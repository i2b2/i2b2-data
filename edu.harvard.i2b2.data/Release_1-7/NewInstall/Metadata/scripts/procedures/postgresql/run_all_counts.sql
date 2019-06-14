----------------------------------------------------------------------------------------------------------------------------------------
-- 6/8/2016 
-- Modified for PostgreSQL by Dan Vianello, Center for Biomedical Informatics, Washington University in St. Louis
-- If you have questions or issues with the script, please contact i2b2admin@bmi.wustl.edu 
-- Team at WashU: Snehil Gupta, Connie Zabarovskaya, Brian Romine, Dan Vianello

-- DISCLAIMER for PostgreSQL: the code assumes that pcornet_ tables are in i2b2metadata schema, while observation_fact 
-- and dimension tables are in i2b2demodata schema. If your schema structure is different, 
-- please adjust the code accordingly.
----------------------------------------------------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------
-- run_all_counts(tablename)
-- DEPENDS: on functsions -PAT_VISIT_COUNTS, PAT_COUNT_BY_CONCEPT,PAT_COUNT_BY_PROVIDER,
-- PAT_COUNT_IN_EQUAL, PAT_COUNT_MODIFIERS
-----------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION run_all_counts(tablename text)
  RETURNS void AS
$BODY$
declare 
    sqlstr text;
    v_numpats integer;
BEGIN      
    --display count and timing information to the user
    raise info 'At %, running run_all_counts(''%'')',clock_timestamp(), tablename;
	sqlstr := 'update ' || tablename || ' set c_totalnum=null';
	execute sqlstr;

    perform PAT_VISIT_COUNTS(tablename,'''');
    perform PAT_COUNT_BY_CONCEPT(tablename,''observation_fact'');
   -- perform PAT_COUNT_BY_PROVIDER(tablename,''observation_fact'');
   -- perform PAT_COUNT_IN_EQUAL(tablename,''observation_fact'');
   -- perform PAT_COUNT_MODIFIERS(tablename,''observation_fact'');

	sqlstr := 'update ' || tablename || ' set c_totalnum=null where c_visualattributes = ''CA'' and c_totalnum = 0';
	execute sqlstr;

    --display count and timing information to the user
	execute 'select count(*) from '||tablename||' where c_totalnum is not null and c_totalnum <> 0' into v_numpats ;
    raise info 'At %, finished running run_all_counts(''%''); populated % recods.',clock_timestamp(), tablename, v_numpats;
END; 
$BODY$
  LANGUAGE plpgsql VOLATILE SECURITY DEFINER
  COST 100;