-----------------------------------------------------------------------------------------------------------------
/*********************************************************
*         SNOWFLAKE IMPLEMENATION FOR RUNNING pat_count_visits FUNCTION
*         Based on implementation from Postgresql
*         MD SABER HOSSAIN	7/14/2023
/*        University of Missouri-Columbia			
**********************************************************/

CREATE OR REPLACE PROCEDURE pat_count_visits(
    tabname VARCHAR, 
    tableschema VARCHAR
)
RETURNS INT 
LANGUAGE SQL
AS
DECLARE 
    v_sqlstr TEXT;
    -- using cursor defined withing FOR RECORD IN QUERY loop below.
    cur CURSOR FOR select c_fullname, c_facttablecolumn, c_tablename, c_columnname, c_operator, c_dimcode from ontPatVisitDims;
    v_num INTEGER;
    c_dimcode VARCHAR;
BEGIN
    --display count and timing information to the user
  
    --using all temporary tables instead of creating and dropping tables
    drop table if exists ontPatVisitDims;

    --checking each text fields for forced lowercase values since DB defaults to case sensitive 
	v_sqlstr := 'create temp table ontPatVisitDims as '
          ||    ' select c_fullname'
          ||          ', c_basecode'
          ||          ', c_facttablecolumn'
          ||          ', c_tablename'
          ||          ', c_columnname'
          ||          ', c_operator'
          ||          ', c_dimcode'
          ||          ', null::integer as numpats'
          ||      ' from ' || tabname
          ||      ' where  m_applied_path = ''@'''
          ||        ' and lower(c_tablename) in (''patient_dimension'', ''visit_dimension'') ';

    EXECUTE IMMEDIATE :v_sqlstr;
    
    FOR curRecord IN cur DO
        
      -- CREATE INDEX ontPatVisitDimsfname ON ontPatVisitDims(c_fullname);
    
    -- ACT_VISIT_DETAILS_V4 age at visit subquery in c_dimcode
    /*

     select count(distinct(patient_num))  from I2B2DATA.visit_dimension 
     where start_date BETWEEN 
     (select min(birth_date) + (INTERVAL '4 months') from PATIENT_DIMENSION where patient_num =VISIT_DIMENSION.PATIENT_NUM) AND 
     (select min(birth_date) + (INTERVAL '5 months')  - (INTERVAL '1 day') from PATIENT_DIMENSION where patient_num =VISIT_DIMENSION.PATIENT_NUM)
     */
        IF (tabname = 'ACT_VISIT_DETAILS_V4') THEN
            c_dimcode := replace(curRecord.c_dimcode, 'from PATIENT_DIMENSION', 'from ' || tableschema || '.' || 'PATIENT_DIMENSION');
        ELSE
            c_dimcode := curRecord.c_dimcode;
        END IF;

       v_sqlstr := 'update ontPatVisitDims '
       || ' set numpats =  ( '                     
       ||     ' select count(distinct(patient_num)) '
       ||     ' from ' || tableschema || '.' || curRecord.c_tablename 
       ||         ' where '|| curRecord.c_columnname || ' '  ;
       CASE 
           WHEN lower(curRecord.c_columnname) = 'birth_date' 
                 and lower(curRecord.c_tablename) = 'patient_dimension'
                 and lower(c_dimcode) like '%not recorded%' then 
                    v_sqlstr := v_sqlstr || ' is null';
            WHEN lower(curRecord.c_operator) = 'like' then 
                v_sqlstr := v_sqlstr || curRecord.c_operator  || ' ' || '''' || replace(replace(c_dimcode,'\\','\\\\'),'''','''''') || '%''' ;
           WHEN lower(curRecord.c_operator) = 'in' then 
           		IF (left(c_dimcode,1)='()') THEN
	                v_sqlstr := v_sqlstr || curRecord.c_operator  || ' ' || c_dimcode;
	            ELSE
	                v_sqlstr := v_sqlstr || curRecord.c_operator  || ' ' ||  '(' || c_dimcode || ')';
				END IF;	            
            WHEN lower(curRecord.c_operator) = '=' then 
                v_sqlstr := v_sqlstr || curRecord.c_operator  || ' ''' ||  replace(c_dimcode,'''','''''') || '''';
            ELSE 
                v_sqlstr := v_sqlstr || curRecord.c_operator  || ' ' || c_dimcode; 
            END;
            
            v_sqlstr := v_sqlstr -- || ' ) ' -- in
                     || ' ) ' -- set
                     || ' where c_fullname = ' || '''' || replace(curRecord.c_fullname,'\\','\\\\') || '''' 
                     || ' and numpats is null';

            begin
                execute IMMEDIATE :v_sqlstr;
                EXCEPTION WHEN OTHER THEN
                return 0;
            END;
	
    END FOR;


	v_sqlstr := 'update ' || tabname || ' a set c_totalnum=b.numpats '
             || ' from ontPatVisitDims b '
             || ' where a.c_fullname=b.c_fullname and b.numpats>0';

    --raise info 'At %: Running: %',clock_timestamp()e, v_sqlstr;
 
    --display count and timing information to the user
    select count(*) into :v_num from ontPatVisitDims where numpats is not null and numpats <> 0;
    --raise info 'At %, updating c_totalnum in % for % records',clock_timestamp(), tabname, v_num;
             
	EXECUTE IMMEDIATE :v_sqlstr;
	
	-- New 4/2020 - Update the totalnum reporting table as well
	insert into totalnum(c_fullname, agg_date, agg_count, typeflag_cd)
	select c_fullname, current_date, numpats, 'PD' from ontPatVisitDims;
	
    drop table if exists ontPatVisitDims;
    RETURN 1;
END;