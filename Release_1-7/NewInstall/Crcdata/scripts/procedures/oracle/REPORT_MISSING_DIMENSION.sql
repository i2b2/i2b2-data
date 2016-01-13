CREATE OR REPLACE PROCEDURE REPORT_MISSING_DIMENSION(upload_temptable_name IN VARCHAR)
IS
BEGIN
--Missing Concept Code
execute immediate 'INSERT ALL INTO missing_dimension_report 
SELECT concept_cd dimension_value,count(*) total_count,''C'' dimension, upload_id FROM ' ||upload_temptable_name ||' temp
WHERE temp.concept_cd NOT IN (SELECT concept_cd FROM concept_dimension)
group by concept_cd,upload_id';

--Missing Encounter Ide
execute immediate 'INSERT ALL INTO missing_dimension_report
SELECT encounter_ide dimension_value,count(*) total_count,''E'' dimension, upload_id FROM ' ||upload_temptable_name ||' temp
WHERE temp.encounter_ide NOT IN (SELECT encounter_ide FROM encounter_mapping)
group by encounter_ide,upload_id';


--Missing Patient Ide
execute immediate 'INSERT ALL INTO missing_dimension_report 
SELECT patient_ide dimension_value,count(*) total_count,''P'' dimension, upload_id FROM ' ||upload_temptable_name ||' temp
WHERE temp.patient_ide NOT IN (SELECT patient_ide FROM patient_mapping)
group by patient_ide,upload_id';


EXCEPTION
	WHEN OTHERS THEN
		raise_application_error(-20001,'An error was encountered - '||SQLCODE||' -ERROR- '||SQLERRM);	
END;
