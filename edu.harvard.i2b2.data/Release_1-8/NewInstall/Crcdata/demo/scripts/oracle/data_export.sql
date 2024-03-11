
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
	<Query>SELECT   a.PATIENT_NUM as "i2b2 Patient Number"
      ,a.BIRTH_DATE as "Birth Date"
      ,a.SEX_CD as "Gender"
      , a.AGE_IN_YEARS_NUM as "Age in Years"
      ,a.LANGUAGE_CD as "Primary Spoken Language"
      ,a.RACE_CD as "Race"
      ,a.MARITAL_STATUS_CD as "Marital Status"
      ,a.RELIGION_CD as "Religion"
      ,a.ZIP_CD as "Zip Code"
      ,a.STATECITYZIP_PATH as "State and Zip"
      ,a.INCOME_CD as "Income"
      ,a.VITAL_STATUS_CD as "Vital Status"
      , a.DEATH_DATE as "Death Date"
  FROM patient_dimension a, {{{DX}}} c
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
  <LetterFilename>/tmp/{{{PROJECT_ID}}}/Readme.txt</LetterFilename>
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
	<Query>ELECT distinct   a.PATIENT_NUM as "i2b2 Patient Number"
        ,m.patient_ide as "MRN"
      ,a.start_date as "Start Date"
      ,a.end_date as "End Date"      
      ,b.name_char as "Medication Name"
      ,b.concept_cd as "NDC Code"
      ,b.units_cd as "Unit"
      ,a.quantity_num as "Dose Quantity"
      ,a.location_cd as "Clinic"
      ,case v.inout_cd  when ''O'' then ''Outpatient'' when ''I'' then ''Inpatient'' else ''Unknown'' end as "Inpatient or Outpatient"
     ,p.name_char as "Provider"
     ,a.encounter_num as "Encounter Number"
  FROM observation_fact  a 
    inner  join concept_dimension b on 
    a.concept_cd = b.concept_cd and
   b.concept_path like ''\i2b2\Medications\%''
   left outer join {{{DX}}} c on
   a.patient_num = c.patient_num
 left join provider_dimension p on
   a.provider_id = p.provider_id
 left join visit_dimension v on
   a.encounter_num = v.encounter_num and
   a.patient_num = v.patient_num
left join patient_mapping m on
   a.patient_num = m.patient_num</Query>
      	<SeparatorCharacter>\t</SeparatorCharacter>
  </Table>

</ValueExporter>',null,null,null)
;