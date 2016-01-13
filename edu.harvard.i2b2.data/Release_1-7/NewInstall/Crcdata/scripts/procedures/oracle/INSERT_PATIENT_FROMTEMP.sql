CREATE OR REPLACE PROCEDURE "INSERT_PATIENT_FROMTEMP"(tempTableName IN VARCHAR,upload_id IN NUMBER,
  errorMsg OUT VARCHAR) 
AS
maxPatientNum number; 

BEGIN 
 
     LOCK TABLE  patient_mapping IN EXCLUSIVE MODE NOWAIT;
     --select max(patient_num) into maxPatientNum from patient_mapping ;

	 --Create new patient(patient_mapping) if temp table patient_ide does not exists 
	-- in patient_mapping table.
     execute immediate ' insert into patient_mapping (patient_ide,patient_ide_source,patient_num,patient_ide_status, upload_id)
     	(select distinctTemp.patient_id, distinctTemp.patient_id_source, distinctTemp.patient_id, ''A'',   '|| upload_id ||'
				from 
					(select distinct patient_id, patient_id_source from ' || tempTableName || '  temp
					where  not exists (select patient_ide from patient_mapping pm where pm.patient_ide = temp.patient_id and pm.patient_ide_source = temp.patient_id_source)
					 and patient_id_source = ''HIVE'' )   distinctTemp) ';


-- update patient_num for temp table
 execute immediate ' UPDATE ' ||  tempTableName
 || ' SET patient_num = (SELECT pm.patient_num
		     FROM patient_mapping pm
		     WHERE pm.patient_ide = '|| tempTableName ||'.patient_id
                     and pm.patient_ide_source = '|| tempTableName ||'.patient_id_source
	 	    )
WHERE EXISTS (SELECT pm.patient_num 
		     FROM patient_mapping pm
		     WHERE pm.patient_ide = '|| tempTableName ||'.patient_id
                     and pm.patient_ide_source = '||tempTableName||'.patient_id_source)';	



   execute immediate ' UPDATE patient_dimension  set  (VITAL_STATUS_CD, BIRTH_DATE, DEATH_DATE,
					SEX_CD, AGE_IN_YEARS_NUM,LANGUAGE_CD,RACE_CD,MARITAL_STATUS_CD, RELIGION_CD,
					ZIP_CD,STATECITYZIP_PATH,PATIENT_BLOB,UPDATE_DATE,DOWNLOAD_DATE,IMPORT_DATE,SOURCESYSTEM_CD,
			     	UPLOAD_ID) = (select temp.VITAL_STATUS_CD, temp.BIRTH_DATE, temp.DEATH_DATE,
					temp.SEX_CD, temp.AGE_IN_YEARS_NUM,temp.LANGUAGE_CD,temp.RACE_CD,temp.MARITAL_STATUS_CD, temp.RELIGION_CD,
					temp.ZIP_CD,temp.STATECITYZIP_PATH,temp.PATIENT_BLOB,temp.update_date,temp.DOWNLOAD_DATE,sysdate,temp.SOURCESYSTEM_CD,
			     	' || UPLOAD_ID  || ' from ' || tempTableName || '  temp   where 
					temp.patient_num = patient_dimension.patient_num and temp.update_date >= patient_dimension.update_date) 
					where exists (select 1 from ' || tempTableName || ' temp  where temp.patient_num = patient_dimension.patient_num 
					and temp.update_date >= patient_dimension.update_date) ';


	--Create new patient(patient_dimension) for above inserted patient's.
	--If patient_dimension table's patient num does match temp table,
	--then new patient_dimension information is inserted.
	execute immediate 'insert into patient_dimension  (PATIENT_NUM,VITAL_STATUS_CD, BIRTH_DATE, DEATH_DATE,
					SEX_CD, AGE_IN_YEARS_NUM,LANGUAGE_CD,RACE_CD,MARITAL_STATUS_CD, RELIGION_CD,
					ZIP_CD,STATECITYZIP_PATH,PATIENT_BLOB,UPDATE_DATE,DOWNLOAD_DATE,IMPORT_DATE,SOURCESYSTEM_CD,
			     	UPLOAD_ID)
	               select temp.patient_num,
					temp.VITAL_STATUS_CD, temp.BIRTH_DATE, temp.DEATH_DATE,
					temp.SEX_CD, temp.AGE_IN_YEARS_NUM,temp.LANGUAGE_CD,temp.RACE_CD,temp.MARITAL_STATUS_CD, temp.RELIGION_CD,
					temp.ZIP_CD,temp.STATECITYZIP_PATH,temp.PATIENT_BLOB,
					temp.update_date,
					temp.download_date,
					sysdate, -- import date
					temp.sourcesystem_cd,
		            '|| upload_id ||'
			from 
				' || tempTableName || '  temp 
			where 
		      	 not exists (select patient_num from patient_dimension pd where pd.patient_num = temp.patient_num) and 
                 patient_num is not null
	 ';
		        

    commit;
EXCEPTION
	WHEN OTHERS THEN
	    rollback;
		dbms_output.put_line(SQLCODE|| ' - ' ||SQLERRM);
END;