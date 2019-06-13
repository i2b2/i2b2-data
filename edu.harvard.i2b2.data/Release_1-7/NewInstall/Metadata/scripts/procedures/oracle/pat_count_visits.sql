create or replace PROCEDURE              pat_count_visit  (metadataTable IN VARCHAR, observationTable IN VARCHAR, 
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
 EXECUTE IMMEDIATE 'drop table ontPatVisitDims';
 EXECUTE IMMEDIATE 'drop table conceptCountOntWithFolders';
 EXECUTE IMMEDIATE 'drop table finalCountsByConcept';
EXCEPTION
  WHEN OTHERS THEN
  NULL;


execute immediate 'create table ontPatVisitDims as select c_fullname
        , c_basecode
          , c_facttablecolumn
        , c_tablename
          , c_columnnamea
        , c_operator
          , c_dimcode
          , c_totalnum as numpats
	from '  || metadataTable  || ' where  m_applied_path = ''@''
          and lower(c_tablename) in (''patient_dimension'', ''visit_dimension'') ';

 sql_stmt := 'select c_fullname, c_facttablecolumn, c_tablename, c_columnname, c_operator, c_dimcode from ontPatVisitDims ';
 

 open curRecord for sql_stmt ;
 
   loop
    FETCH curRecord INTO dis_c_fullname, dis_c_facttablecolumn, dis_c_tablename, dis_c_columnname, dis_c_operator, dis_c_dimcode;
      EXIT WHEN curRecord%NOTFOUND;
 
            sql_stmt := 'update ontPatVisitDims '
                     || ' set numpats =  ( '                     
                     ||     ' select count(distinct(patient_num)) '
                     ||     ' from i2b2demodata.' || dis_c_tablename 
                     ||         ' where '|| dis_c_columnname || ' '  ;

            CASE 
            WHEN lower(dis_c_columnname) = 'birth_date' 
                 and lower(dis_c_tablename) = 'patient_dimension'
                 and lower(dis_c_dimcode) like '%not recorded%' then 
                    sql_stmt := sql_stmt || ' is null';
            WHEN lower(dis_c_operator) = 'like' then 
sql_stmt := sql_stmt || dis_c_operator  || ' ' || '''' || replace(dis_c_dimcode,'''','''''') || '%''' ;
            WHEN lower(dis_c_operator) = 'in' then 
                sql_stmt := sql_stmt || dis_c_operator  || ' ' ||  '(' || dis_c_dimcode || ')';
            WHEN lower(dis_c_operator) = '=' then 
                sql_stmt := sql_stmt || dis_c_operator  || ' ' ||  '''' || dis_c_dimcode || '''' ;
            ELSE 
            END CASE;
            
            sql_stmt := sql_stmt -- || ' ) ' -- in
                     || ' ) ' -- set
                     || ' where c_fullname = ' || '''' || dis_c_fullname || '''' 
                     || ' and numpats is null';

         execute immediate sql_stmt;
    END LOOP;



END;
