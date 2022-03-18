CREATE OR REPLACE FUNCTION public.insert_concept_dimension_fromtableaccess(OUT errormsg text)
 RETURNS text
 LANGUAGE plpgsql
AS $function$

DECLARE 
	sqltext VARCHAR(4000);
	getsql cursor for
		select
	'insert into concept_dimension 
		select distinct c_dimcode AS concept_path, 
		c_basecode AS concept_cd, 
		c_name AS name_char, 
		null AS concept_blob, 
		update_date AS update_date, 
		download_date as download_date, 
		import_date as import_date, 
		sourcesystem_cd as sourcesystem_cd, 
		1 as upload_id 
		from ' || c_table_name || ' 
		where m_applied_path=''@'' 
		and lower(c_tablename)=''concept_dimension'' 
		and lower(c_columnname)=''concept_path''
		and (c_columndatatype=''T'' or c_columndatatype=''N'') 
		and c_synonym_cd = ''N'' 
		and (m_exclusion_cd is null or m_exclusion_cd='''') 
		and c_basecode is not null and c_basecode!='''''
from
	TABLE_ACCESS
where
	c_visualattributes like '%A%';

BEGIN
DELETE FROM concept_dimension;
OPEN getsql;
FETCH NEXT FROM getsql INTO sqltext;

loop
	execute sqltext;
	FETCH NEXT FROM getsql INTO sqltext;
	IF not found THEN EXIT;
	END IF;
END LOOP;
CLOSE getsql;
END;
$function$
;
