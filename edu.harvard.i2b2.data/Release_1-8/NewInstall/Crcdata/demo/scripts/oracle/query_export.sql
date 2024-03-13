
insert into QT_BREAKDOWN_PATH (NAME,VALUE,CREATE_DATE,UPDATE_DATE,USER_ID) values ('PATIENT_DEMOGRAPHIC_CSV','<?xml version="1.0"?>
<ValueExporter>
  <Version>3.02</Version>
  <CreationDateTime>08/09/2024 12:00:00</CreationDateTime>
  <RequesterEmailLetter>Your request on {{{PROJECT_ID}}} requested i2b2 request
 entitled - "{{{QUERY_NAME}}}", submitted on {{{QUERY_STARTDATE}}}, with the query master of {{{QUERY_ID}}}</RequesterEmailLetter>
  <RequestLetter>This user {{{USER_NAME}}} in project {{{PROJECT_ID}}} requested i2b2 request
 entitled - "{{{QUERY_NAME}}}", submitted on {{{QUERY_STARTDATE}}}, with the query master of {{{QUERY_ID}}}.
  </RequestLetter>
  <LetterFilename>/{{{USER_NAME}}}/{{{QUERY_MASTER_ID}}}/Readme.txt</LetterFilename>
  <Letter>
Results of the i2b2 request entitled - "{{{QUERY_NAME}}}", submitted on {{{QUERY_STARTDATE}}}, are available.

Important notes about your data:
	- Total number of patients returned in your data request: {{{PATIENT_COUNT}}}
	- i2b2 reviewer:
	
Only persons specifically authorized and selected (as listed at the top of this letter) can download these files. If additional user access is needed, please ensure the person is listed on your project IRB protocol and contact the i2b2 team.
 
Specifically:
	- Remove all PHI from computer, laptop, or mobile device after analysis is completed.
	- Do NOT share PHI or PII with anyone who is not listed on the IRB protocol.

Your guideline for the storage of Protected Health Information can be found at: https://www.site.com/guidelines_for_protecting_and_storing_phi.pdf

*To download these files*
- You must be logged onto your site

These results are the data that was requested under the authority of the Institutional Review Board.  The query resulting in this identified patient data is included at the end of this letter.  A copy of this letter is kept on file and is available to the IRB in the event of an audit.

Thank you,

The i2b2 Team </Letter>
  <Table>
	<Filename>/{{{USER_NAME}}}/{{{QUERY_MASTER_ID}}}/Demographics.csv</Filename>
	<Query>SELECT   to_char(a.PATIENT_NUM) as "I2B2_PATIENT_NUMBER"
      ,a.BIRTH_DATE as "BIRTH_DATE"
      , a.DEATH_DATE as "DEATH_DATE"
      ,a.SEX_CD as "GENDER"
      , a.AGE_IN_YEARS_NUM as "AGE_IN_YEARS"
      ,a.LANGUAGE_CD as "PRIMARY_SPOKEN_LANGUAGE"
      ,a.RACE_CD as "RACE"
      ,a.MARITAL_STATUS_CD as "MARTIAL_STATUS"
      ,a.RELIGION_CD as "RELIGION"
      ,a.ZIP_CD as "ZIP_CODE"
      ,a.STATECITYZIP_PATH as "STATE_CITY_ZIP"
      ,a.INCOME_CD as "INCOME"
      ,a.VITAL_STATUS_CD as "VITAL_STATUS"
  FROM patient_dimension a, {{{DX}}} c
  where a.patient_num = c.patient_num</Query>
      	<SeparatorCharacter>\t</SeparatorCharacter>
  </Table>

</ValueExporter>',null,null,null)
;
insert into QT_BREAKDOWN_PATH (NAME,VALUE,CREATE_DATE,UPDATE_DATE,USER_ID) values ('PATIENT_MAPPING_CSV','<?xml version="1.0"?>
<ValueExporter>
  <Version>3.02</Version>
  <CreationDateTime>08/09/2024 12:00:00</CreationDateTime>
  <RequesterEmailLetter>Your request on {{{PROJECT_ID}}} requested i2b2 request
 entitled - "{{{QUERY_NAME}}}", submitted on {{{QUERY_STARTDATE}}}, with the query master of {{{QUERY_ID}}}</RequesterEmailLetter>
  <RequestLetter>This user {{{USER_NAME}}} in project {{{PROJECT_ID}}} requested i2b2 request
 entitled - "{{{QUERY_NAME}}}", submitted on {{{QUERY_STARTDATE}}}, with the query master of {{{QUERY_ID}}}.
  </RequestLetter>
  <LetterFilename>/{{{USER_NAME}}}/{{{QUERY_MASTER_ID}}}/Readme.txt</LetterFilename>
  <Letter>
Results of the i2b2 request entitled - "{{{QUERY_NAME}}}", submitted on {{{QUERY_STARTDATE}}}, are available.

Important notes about your data:
	- Total number of patients returned in your data request: {{{PATIENT_COUNT}}}
	- i2b2 reviewer:
	
Only persons specifically authorized and selected (as listed at the top of this letter) can download these files. If additional user access is needed, please ensure the person is listed on your project IRB protocol and contact the i2b2 team.
 
Specifically:
	- Remove all PHI from computer, laptop, or mobile device after analysis is completed.
	- Do NOT share PHI or PII with anyone who is not listed on the IRB protocol.

Your guideline for the storage of Protected Health Information can be found at: https://www.site.com/guidelines_for_protecting_and_storing_phi.pdf

*To download these files*
- You must be logged onto your site

These results are the data that was requested under the authority of the Institutional Review Board.  The query resulting in this identified patient data is included at the end of this letter.  A copy of this letter is kept on file and is available to the IRB in the event of an audit.

Thank you,

The i2b2 Team </Letter>
  <Table>
	<Filename>/{{{USER_NAME}}}/{{{QUERY_MASTER_ID}}}/PatientMapping.csv</Filename>
	<Query>SELECT DISTINCT to_char(a.PATIENT_NUM) as "I2B2_PATIENT_NUMBER"
      ,a.PATIENT_IDE_SOURCE as "PATIENT_SOURCE"
      ,a.PATIENT_IDE as "PATIENT_IDE"
  FROM patient_mapping a, {{{DX}}} c
  where a.patient_num = c.patient_num</Query>
      	<SeparatorCharacter>\t</SeparatorCharacter>
  </Table>

</ValueExporter>',null,null,null)
;
insert into QT_BREAKDOWN_PATH (NAME,VALUE,CREATE_DATE,UPDATE_DATE,USER_ID) values ('ENCOUNTER_MAPPING_CSV','<?xml version="1.0"?>
<ValueExporter>
  <Version>3.02</Version>
  <CreationDateTime>08/09/2024 12:00:00</CreationDateTime>
  <RequesterEmailLetter>Your request on {{{PROJECT_ID}}} requested i2b2 request
 entitled - "{{{QUERY_NAME}}}", submitted on {{{QUERY_STARTDATE}}}, with the query master of {{{QUERY_ID}}}</RequesterEmailLetter>
  <RequestLetter>This user {{{USER_NAME}}} in project {{{PROJECT_ID}}} requested i2b2 request
 entitled - "{{{QUERY_NAME}}}", submitted on {{{QUERY_STARTDATE}}}, with the query master of {{{QUERY_ID}}}.
  </RequestLetter>
  <LetterFilename>/{{{USER_NAME}}}/{{{QUERY_MASTER_ID}}}/Readme.txt</LetterFilename>
  <Letter>
Results of the i2b2 request entitled - "{{{QUERY_NAME}}}", submitted on {{{QUERY_STARTDATE}}}, are available.

Important notes about your data:
	- Total number of patients returned in your data request: {{{PATIENT_COUNT}}}
	- i2b2 reviewer:
	
Only persons specifically authorized and selected (as listed at the top of this letter) can download these files. If additional user access is needed, please ensure the person is listed on your project IRB protocol and contact the i2b2 team.
 
Specifically:
	- Remove all PHI from computer, laptop, or mobile device after analysis is completed.
	- Do NOT share PHI or PII with anyone who is not listed on the IRB protocol.

Your guideline for the storage of Protected Health Information can be found at: https://www.site.com/guidelines_for_protecting_and_storing_phi.pdf

*To download these files*
- You must be logged onto your site

These results are the data that was requested under the authority of the Institutional Review Board.  The query resulting in this identified patient data is included at the end of this letter.  A copy of this letter is kept on file and is available to the IRB in the event of an audit.

Thank you,

The i2b2 Team </Letter>
  <Table>
	<Filename>/{{{USER_NAME}}}/{{{QUERY_MASTER_ID}}}/EncounterMapping.csv</Filename>
	<Query>SELECT DISTINCT to_char(a.PATIENT_NUM) as "I2B2_PATIENT_NUMBER"
      ,a.PATIENT_IDE_SOURCE as "PATIENT_SOURCE"
      ,a.PATIENT_IDE as "PATIENT_IDE"
      ,a.ENCOUNTER_IDE_SOURCE as "ENCOUNTER_SOURCE"
      ,a.ENCOUNTER_IDE as "ENCOUNTER_IDE"
  FROM encounter_mapping a, {{{DX}}} c
  where a.patient_num = c.patient_num</Query>
      	<SeparatorCharacter>\t</SeparatorCharacter>
  </Table>

</ValueExporter>',null,null,null)
;

insert into QT_BREAKDOWN_PATH (NAME,VALUE,CREATE_DATE,UPDATE_DATE,USER_ID) values ('PATIENT_MEDICATION_CSV','<?xml version="1.0"?>
<ValueExporter>
  <Version>3.02</Version>
  <CreationDateTime>08/09/2024 12:00:00</CreationDateTime>
  <RequesterEmailLetter>Your request on {{{PROJECT_ID}}} requested i2b2 request
 entitled - "{{{QUERY_NAME}}}", submitted on {{{QUERY_STARTDATE}}}, with the query master of {{{QUERY_ID}}}</RequesterEmailLetter>
  <RequestLetter>This user {{{USER_NAME}}} in project {{{PROJECT_ID}}} requested i2b2 request
 entitled - "{{{QUERY_NAME}}}", submitted on {{{QUERY_STARTDATE}}}, with the query master of {{{QUERY_ID}}}.
  </RequestLetter>
  <LetterFilename>/{{{USER_NAME}}}/{{{QUERY_MASTER_ID}}}/Readme.txt</LetterFilename>
  <Letter>
Results of the i2b2 request entitled - "{{{QUERY_NAME}}}", submitted on {{{QUERY_STARTDATE}}}, are available.

Important notes about your data:
	- Total number of patients returned in your data request: {{{PATIENT_COUNT}}}
	- i2b2 reviewer:
	
Only persons specifically authorized and selected (as listed at the top of this letter) can download these files. If additional user access is needed, please ensure the person is listed on your project IRB protocol and contact the i2b2 team.
 
Specifically:
	- Remove all PHI from computer, laptop, or mobile device after analysis is completed.
	- Do NOT share PHI or PII with anyone who is not listed on the IRB protocol.

Your guideline for the storage of Protected Health Information can be found at: https://www.site.com/guidelines_for_protecting_and_storing_phi.pdf

*To download these files*
- You must be logged onto your site

These results are the data that was requested under the authority of the Institutional Review Board.  The query resulting in this identified patient data is included at the end of this letter.  A copy of this letter is kept on file and is available to the IRB in the event of an audit.

Thank you,

The i2b2 Team 
</Letter>
  <Table>
	<Filename>/{{{USER_NAME}}}/{{{QUERY_MASTER_ID}}}/Medication.csv</Filename>
	<Query>SELECT DISTINCT to_char(a.PATIENT_NUM) as "I2B2_PATIENT_NUMBER"
        ,m.patient_ide as ”PATIENT_ID"
        ,a.start_date as "START_DATE"
        ,a.start_date as "END_DATE"
        ,b.name_char as "MEDICATION_NAME"
        ,b.concept_cd as "NDC_CODE"
      ,a.units_cd as "UNIT"
      ,a.quantity_num as "DOSE_QUANTITY"        
        ,b.modifier_cd as "MODIFIER"
        ,a.location_cd as "FACILITY" 
       ,case v.inout_cd  when ''O'' then ''Outpatient'' when ''I'' then ''Inpatient'' else ''Unknown'' end as "ENCOUNTER_TYPE"
        ,p.name_char as "PROVIDER"
        ,a.encounter_num as "ENCOUNTER_NUMBER"
    FROM observation_fact  a 
    INNER  JOIN concept_dimension b on a.concept_cd = b.concept_cd and b.concept_path like ''\i2b2\Medications\%''
    JOIN {{{DX}}} c on a.patient_num = c.patient_num
    LEFT OUTER JOIN provider_dimension p on a.provider_id = p.provider_id
    JOIN visit_dimension v on a.encounter_num = v.encounter_num and a.patient_num = v.patient_num
    JOIN patient_mapping m on a.patient_num = m.patient_num;</Query>
      	<SeparatorCharacter>\t</SeparatorCharacter>
  </Table>

</ValueExporter>',null,null,null)
;
insert into QT_BREAKDOWN_PATH (NAME,VALUE,CREATE_DATE,UPDATE_DATE,USER_ID) values ('PATIENT_PROCEDURE_CSV','<?xml version="1.0"?>
<ValueExporter>
  <Version>3.02</Version>
  <CreationDateTime>08/09/2024 12:00:00</CreationDateTime>
  <RequesterEmailLetter>Your request on {{{PROJECT_ID}}} requested i2b2 request
 entitled - "{{{QUERY_NAME}}}", submitted on {{{QUERY_STARTDATE}}}, with the query master of {{{QUERY_ID}}}</RequesterEmailLetter>
  <RequestLetter>This user {{{USER_NAME}}} in project {{{PROJECT_ID}}} requested i2b2 request
 entitled - "{{{QUERY_NAME}}}", submitted on {{{QUERY_STARTDATE}}}, with the query master of {{{QUERY_ID}}}.
  </RequestLetter>
  <LetterFilename>/{{{USER_NAME}}}/{{{QUERY_MASTER_ID}}}/Readme.txt</LetterFilename>
  <Letter>
Results of the i2b2 request entitled - "{{{QUERY_NAME}}}", submitted on {{{QUERY_STARTDATE}}}, are available.

Important notes about your data:
	- Total number of patients returned in your data request: {{{PATIENT_COUNT}}}
	- i2b2 reviewer:
	
Only persons specifically authorized and selected (as listed at the top of this letter) can download these files. If additional user access is needed, please ensure the person is listed on your project IRB protocol and contact the i2b2 team.
 
Specifically:
	- Remove all PHI from computer, laptop, or mobile device after analysis is completed.
	- Do NOT share PHI or PII with anyone who is not listed on the IRB protocol.

Your guideline for the storage of Protected Health Information can be found at: https://www.site.com/guidelines_for_protecting_and_storing_phi.pdf

*To download these files*
- You must be logged onto your site

These results are the data that was requested under the authority of the Institutional Review Board.  The query resulting in this identified patient data is included at the end of this letter.  A copy of this letter is kept on file and is available to the IRB in the event of an audit.

Thank you,

The i2b2 Team 
</Letter>
  <Table>
	<Filename>/{{{USER_NAME}}}/{{{QUERY_MASTER_ID}}}/Procedure.csv</Filename>
	<Query>SELECT DISTINCT to_char(a.PATIENT_NUM) as "I2B2_PATIENT_NUMBER"
        ,m.patient_ide as ”PATIENT_ID"
        ,a.start_date as "START_DATE"
        ,a.start_date as "END_DATE"
        ,b.name_char as "PROCEDURE_NAME"
        ,b.concept_cd as "PROCEDURE_CODE"
        ,a.quantity_num as "QUANTITY"
        ,b.modifier_cd as "MODIFIER"
        ,a.location_cd as "FACILITY" 
        ,case v.inout_cd  when ''O'' then ''Outpatient'' when ''I'' then ''Inpatient'' else ''Unknown'' end as "ENCOUNTER_TYPE"
        ,p.name_char as "PROVIDER"
        ,a.encounter_num as "ENCOUNTER_NUMBER"
    FROM observation_fact  a 
    INNER  JOIN concept_dimension b on a.concept_cd = b.concept_cd and b.concept_path like ''\i2b2\Procedures\%''
    JOIN {{{DX}}} c on a.patient_num = c.patient_num
    LEFT OUTER JOIN provider_dimension p on a.provider_id = p.provider_id
    JOIN visit_dimension v on a.encounter_num = v.encounter_num and a.patient_num = v.patient_num
    JOIN patient_mapping m on a.patient_num = m.patient_num    
     </Query>
      	<SeparatorCharacter>\t</SeparatorCharacter>
  </Table>

</ValueExporter>',null,null,null)
;
insert into QT_BREAKDOWN_PATH (NAME,VALUE,CREATE_DATE,UPDATE_DATE,USER_ID) values ('PATIENT_DIAGNOSIS_CSV','<?xml version="1.0"?>
<ValueExporter>
  <Version>3.02</Version>
  <CreationDateTime>08/09/2024 12:00:00</CreationDateTime>
  <RequesterEmailLetter>Your request on {{{PROJECT_ID}}} requested i2b2 request
 entitled - "{{{QUERY_NAME}}}", submitted on {{{QUERY_STARTDATE}}}, with the query master of {{{QUERY_ID}}}</RequesterEmailLetter>
  <RequestLetter>This user {{{USER_NAME}}} in project {{{PROJECT_ID}}} requested i2b2 request
 entitled - "{{{QUERY_NAME}}}", submitted on {{{QUERY_STARTDATE}}}, with the query master of {{{QUERY_ID}}}.
  </RequestLetter>
  <LetterFilename>/{{{USER_NAME}}}/{{{QUERY_MASTER_ID}}}/Readme.txt</LetterFilename>
  <Letter>
Results of the i2b2 request entitled - "{{{QUERY_NAME}}}", submitted on {{{QUERY_STARTDATE}}}, are available.

Important notes about your data:
	- Total number of patients returned in your data request: {{{PATIENT_COUNT}}}
	- i2b2 reviewer:
	
Only persons specifically authorized and selected (as listed at the top of this letter) can download these files. If additional user access is needed, please ensure the person is listed on your project IRB protocol and contact the i2b2 team.
 
Specifically:
	- Remove all PHI from computer, laptop, or mobile device after analysis is completed.
	- Do NOT share PHI or PII with anyone who is not listed on the IRB protocol.

Your guideline for the storage of Protected Health Information can be found at: https://www.site.com/guidelines_for_protecting_and_storing_phi.pdf

*To download these files*
- You must be logged onto your site

These results are the data that was requested under the authority of the Institutional Review Board.  The query resulting in this identified patient data is included at the end of this letter.  A copy of this letter is kept on file and is available to the IRB in the event of an audit.

Thank you,

The i2b2 Team 
</Letter>
  <Table>
	<Filename>/{{{USER_NAME}}}/{{{QUERY_MASTER_ID}}}/Diagnosis.csv</Filename>
	<Query>SELECT DISTINCT to_char(a.PATIENT_NUM) as "I2B2_PATIENT_NUMBER"
       ,m.patient_ide as ”PATIENT_ID"
       ,a.start_date as "START_DATE"
       ,a.start_date as "END_DATE"
       ,b.name_char as "DIAGNOSIS_NAME"
       ,b.concept_cd as "DIAGNOSIS_CODE"
       ,a.modifier_cd as "MODIFIER"
       ,a.location_cd as "FACILITY" 
       ,case v.inout_cd  when ''O'' then ''Outpatient'' when ''I'' then ''Inpatient'' else ''Unknown'' end as "ENCOUNTER_TYPE"
       ,p.name_char as "PROVIDER"
       ,a.encounter_num as "ENCOUNTER_NUMBER"
   FROM observation_fact  a 
   INNER  JOIN concept_dimension b on a.concept_cd = b.concept_cd and b.concept_path like ''\i2b2\Diagnoses\%''
   JOIN {{{DX}}} c on a.patient_num = c.patient_num
   LEFT OUTER JOIN provider_dimension p on a.provider_id = p.provider_id
   JOIN visit_dimension v on a.encounter_num = v.encounter_num and a.patient_num = v.patient_num
   JOIN patient_mapping m on a.patient_num = m.patient_num
   </Query>
      	<SeparatorCharacter>\t</SeparatorCharacter>
  </Table>

</ValueExporter>',null,null,null)
;
insert into QT_BREAKDOWN_PATH (NAME,VALUE,CREATE_DATE,UPDATE_DATE,USER_ID) values ('PATIENT_LAB_CSV','<?xml version="1.0"?>
<ValueExporter>
  <Version>3.02</Version>
  <CreationDateTime>08/09/2024 12:00:00</CreationDateTime>
  <RequesterEmailLetter>Your request on {{{PROJECT_ID}}} requested i2b2 request
 entitled - "{{{QUERY_NAME}}}", submitted on {{{QUERY_STARTDATE}}}, with the query master of {{{QUERY_ID}}}</RequesterEmailLetter>
  <RequestLetter>This user {{{USER_NAME}}} in project {{{PROJECT_ID}}} requested i2b2 request
 entitled - "{{{QUERY_NAME}}}", submitted on {{{QUERY_STARTDATE}}}, with the query master of {{{QUERY_ID}}}.
  </RequestLetter>
  <LetterFilename>/{{{USER_NAME}}}/{{{QUERY_MASTER_ID}}}/Readme.txt</LetterFilename>
  <Letter>
Results of the i2b2 request entitled - "{{{QUERY_NAME}}}", submitted on {{{QUERY_STARTDATE}}}, are available.

Important notes about your data:
	- Total number of patients returned in your data request: {{{PATIENT_COUNT}}}
	- i2b2 reviewer:
	
Only persons specifically authorized and selected (as listed at the top of this letter) can download these files. If additional user access is needed, please ensure the person is listed on your project IRB protocol and contact the i2b2 team.
 
Specifically:
	- Remove all PHI from computer, laptop, or mobile device after analysis is completed.
	- Do NOT share PHI or PII with anyone who is not listed on the IRB protocol.

Your guideline for the storage of Protected Health Information can be found at: https://www.site.com/guidelines_for_protecting_and_storing_phi.pdf

*To download these files*
- You must be logged onto your site

These results are the data that was requested under the authority of the Institutional Review Board.  The query resulting in this identified patient data is included at the end of this letter.  A copy of this letter is kept on file and is available to the IRB in the event of an audit.

Thank you,

The i2b2 Team 
</Letter>
  <Table>
	<Filename>/{{{USER_NAME}}}/{{{QUERY_MASTER_ID}}}/Lab.csv</Filename>
	<Query>SELECT DISTINCT to_char(a.PATIENT_NUM) as "I2B2_PATIENT_NUMBER"
       ,m.patient_ide as ”PATIENT_ID"
       ,a.start_date as "START_DATE"
       ,a.start_date as "END_DATE"
       ,b.name_char as "LAB_NAME"
       ,b.concept_cd as "LAB_CODE"
       ,case when a.valtype_cd = ''T'' then tval_char else to_char(nval_num) end as "LAB_RESULTS"
       ,a.modifier_cd as "MODIFIER"
       ,a.location_cd as "FACILITY" 
       ,case v.inout_cd  when ''O'' then ''Outpatient'' when ''I'' then ''Inpatient'' else ''Unknown'' end as "ENCOUNTER_TYPE"
       ,p.name_char as "PROVIDER"
       ,a.encounter_num as "ENCOUNTER_NUMBER"
   FROM observation_fact  a 
   INNER  JOIN concept_dimension b on a.concept_cd = b.concept_cd and b.concept_path like ''\i2b2\Labtests\%''
   JOIN {{{DX}}} c on a.patient_num = c.patient_num
   LEFT OUTER JOIN provider_dimension p on a.provider_id = p.provider_id
   JOIN visit_dimension v on a.encounter_num = v.encounter_num and a.patient_num = v.patient_num
   JOIN patient_mapping m on a.patient_num = m.patient_num
	</Query>
      	<SeparatorCharacter>\t</SeparatorCharacter>
  </Table>

</ValueExporter>',null,null,null)
;