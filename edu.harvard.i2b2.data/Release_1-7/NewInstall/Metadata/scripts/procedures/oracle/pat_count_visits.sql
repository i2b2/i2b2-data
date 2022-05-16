create or replace PROCEDURE                 pat_count_visits  (metadataTable IN VARCHAR, schemaName IN VARCHAR, 
   errorMsg OUT VARCHAR)
IS

 TYPE distinctPidCurTyp IS REF CURSOR;
 curRecord   distinctPidCurTyp;
 sql_stmt  varchar2(2000);
 dis_c_fullname varchar2(700);
 dis_c_facttablecolumn varchar2(50);
 dis_c_tablename varchar2(50);
 dis_c_columnname varchar2(50);
 dis_c_operator varchar2(10);
 dis_c_dimcode varchar2(700);

BEGIN
-- EXECUTE IMMEDIATE 'drop table ontPatVisitDims';
--EXCEPTION
--  WHEN OTHERS THEN
--  NULL;

-- Modify this query to select a list of all your ontology paths and basecodes.

execute immediate 'create table ontPatVisitDims as select c_fullname
        , c_basecode
          , c_facttablecolumn
        , c_tablename
          , c_columnname
        , c_operator
          , c_dimcode
          , c_totalnum as numpats
	from '  || metadataTable  || ' where  m_applied_path = ''@''
          and lower(c_tablename) in (''patient_dimension'', ''visit_dimension'') ';

execute immediate 'create index ontPatVisitDims_idx on ontPatVisitDims(c_fullname)';

 sql_stmt := 'select c_fullname, c_facttablecolumn, c_tablename, c_columnname, c_operator, c_dimcode from ontPatVisitDims ';
 

    -- rather than creating cursor and fetching rows into local variables, instead using record variable type to 
    -- access each element of the current row of the cursor
 open curRecord for sql_stmt ;
 
   loop
    FETCH curRecord INTO dis_c_fullname, dis_c_facttablecolumn, dis_c_tablename, dis_c_columnname, dis_c_operator, dis_c_dimcode;
      EXIT WHEN curRecord%NOTFOUND;
 
        -- check first to determine if current columns of current table actually exist in the schema
     --   if exists(select 1 from information_schema.columns 
      --            where table_catalog = current_catalog 
       --             and table_schema = 'i2b2demodata'
       --             and table_name = lower(curRecord.c_tablename)
       --             and column_name = lower(curRecord.c_columnname)
       --          ) then 

            -- simplified query to directly query distinct patient_num instead of querying list of patien_num to feed into outer query for the same
            -- result.  New style runs in approximately half the time as tested with all patients with a particular sex_cd value.  Since all rows 
            -- Since c_facttablecolumn is ALWAYS populated with 'patient_num' for all rows accessed by this function the change to the function is 
            -- worthwhile.  Only in rare cases if changes to the ontology tables are made would the original query be needed, but only where 
            -- c_facttablecolumn would not be 'patient_num AND the values saved in that column in the dimension table are shared between patients that 
            -- don't otherwise have the same ontology would the original method return different results.  It is believed that those results would be 
            -- inaccurate since they would reflect the number of patients who have XXX like patients with this ontology rather than the number of patients
            -- with that ontology. 
            sql_stmt := 'update ontPatVisitDims '
                     || ' set numpats =  ( '                     
                     ||     ' select count(distinct(patient_num)) '
                     ||     ' from ' || schemaName || '.' || dis_c_tablename 
                     --||     ' where ' || curRecord.c_facttablecolumn
                     --||     ' in ( '
                     --||         ' select ' || curRecord.c_facttablecolumn 
                     --||         ' from i2b2demodata.' || curRecord.c_tablename 
                     ||         ' where '|| dis_c_columnname || ' '  ;

            CASE 
            WHEN lower(dis_c_columnname) = 'birth_date' 
                 and lower(dis_c_tablename) = 'patient_dimension'
                 and lower(dis_c_dimcode) like '%not recorded%' then 
                    -- adding specific change of " WHERE patient_dimension.birth_date in ('not_recorded') " to " WHERE patient_dimension.birth_date IS NULL " 
                    -- since IS NULL syntax is not supported in the ontology tables, but the birth_date column is a timestamp datatype and can be null, but cannot be
                    -- the character string 'not recorded'
                    sql_stmt := sql_stmt || ' is null';
            WHEN lower(dis_c_operator) = 'like' then 
                -- escaping escape characters and double quotes.  The additon of '\' to '\\' is needed in Postgres. Alternatively, a custom escape character
                -- could be listed in the query if it is known for certain that that character will never be found in any c_dimcode value accessed by this 
                -- function
   --             sql_stmt := sql_stmt || dis_c_operator  || ' ' || '''' || replace(replace(dis_c_dimcode,'\','\\'),'''','''''') || '%''' ;
				sql_stmt := sql_stmt || dis_c_operator  || ' ' || '''' || replace(dis_c_dimcode,'''','''''') || '%''' ;
            WHEN lower(dis_c_operator) = 'in' then 
                -- With IN statements, () are optional in dimcode
			    if substr(dis_c_dimcode,1,1) = '(' then
				   sql_stmt := sql_stmt || dis_c_operator  || ' ' ||  dis_c_dimcode ;
				else 
                   sql_stmt := sql_stmt || dis_c_operator  || ' ' ||  '(' || dis_c_dimcode || ')';
				end if;
            WHEN lower(dis_c_operator) = '=' then 
      --          sql_stmt := sql_stmt || dis_c_operator  || ' ' ||  replace(dis_c_dimcode,'''','''''') ;
                sql_stmt := sql_stmt || dis_c_operator  || ' ' ||  '''' || dis_c_dimcode || '''' ;
            ELSE 
                -- A mistake in WUSM data existed, requiring special handling in this function.  
                -- The original note is listed next for reference purposes only and the IF THEN 
                -- ELSE block that was needed has been commented out since the original mistake 
                -- in the ontology tables has been corrected.

                /* ORIGINAL NOTE AND CODE
                 *   -- a mistake in WUSM data has this c_dimcode incorrectly listed.  It is being handled in this function until other testing and approvals
                 *   -- are conducted to allow for the correction of this value in the ontology table.
                 *   if curRecord.c_dimcode = 'current_date - interval ''85 year''85 year''' then 
                 *       v_sqlstr := v_sqlstr || curRecord.c_operator  || ' ' || 'current_date - interval ''85 year''';
                 *   else
                 */
                 -- Code to handle NULL dimcodes. This is technically not allowed but could happen on some setups.
                   if dis_c_dimcode is null then 
                        sql_stmt := sql_stmt || dis_c_operator || ' NULL';
                   else
                        sql_stmt := sql_stmt || dis_c_operator  || ' ' || dis_c_dimcode;
                   end if;
                /* 
                 *   end if;
                 */
            END CASE;
            dis_c_fullname := replace(dis_c_fullname,'''','''''') ; -- Escape single quotes in c_fullnames
            sql_stmt := sql_stmt -- || ' ) ' -- in
                     || ' ) ' -- set
                     || ' where c_fullname = ' || '''' || dis_c_fullname || '''' 
                     || ' and numpats is null';

        	--DBMS_OUTPUT.PUT_LINE(sql_stmt);

         execute immediate sql_stmt;
	--	else
            -- do nothing since we do not have the column in our schema
      --  end if;
    END LOOP;


execute immediate 'update ' || metadataTable || '  a  set c_totalnum=
        (select 
        b.numpats 
            from ontPatVisitDims b  
            where a.c_fullname=b.c_fullname and b.numpats>0)';
            
	-- New 4/2020 - Update the totalnum reporting table as well
execute immediate	'insert into totalnum(c_fullname, agg_date, agg_count, typeflag_cd)
	                    select c_fullname, CURRENT_DATE, numpats, ''PD'' from ontPatVisitDims';

 EXECUTE IMMEDIATE 'drop table ontPatVisitDims';

END;