-- Additional indexes on OMOP tables to optimize for i2b2 cohort queries.
-- Index concept_id, person_id
CREATE INDEX idx_visit_concept_person_1 ON visit_occurrence (visit_concept_id,person_id,visit_start_date, visit_end_date ASC);
CREATE INDEX idx_condition_concept_person_1 ON condition_occurrence (condition_concept_id,person_id,condition_start_date, condition_end_date ASC);
CREATE INDEX idx_drug_concept_person_1 ON drug_exposure (drug_concept_id,person_id,drug_exposure_start_date, drug_exposure_end_date ASC);
CREATE INDEX idx_procedure_concept_person_1 ON procedure_occurrence (procedure_concept_id,person_id,procedure_date, procedure_end_date ASC);
CREATE INDEX idx_device_concept_person_1 ON device_exposure (device_concept_id,person_id,device_exposure_start_date, device_exposure_end_date ASC);
CREATE INDEX idx_measurement_concept_person_1 ON measurement (measurement_concept_id,person_id,operator_concept_id, value_as_number, value_as_concept_id,measurement_date ASC);
CREATE INDEX idx_observation_concept_person_1 ON observation (observation_concept_id,person_id,value_as_number, value_as_concept_id,observation_date ASC);


-- Index source_concept_id, person_id
CREATE INDEX idx_visit_sourceconcept_person ON visit_occurrence (visit_source_concept_id,person_id,visit_start_date, visit_end_date ASC);
CREATE INDEX idx_condition_sourceconcept_person ON condition_occurrence (condition_source_concept_id,person_id,condition_start_date, condition_end_date ASC);
CREATE INDEX idx_drug_sourceconcept_person ON drug_exposure (drug_source_concept_id,person_id,drug_exposure_start_date, drug_exposure_end_date ASC);
CREATE INDEX idx_procedure_sourceconcept_person ON procedure_occurrence (procedure_source_concept_id,person_id,procedure_date, procedure_end_date ASC);
CREATE INDEX idx_device_sourceconcept_person ON device_exposure (device_source_concept_id,person_id,device_exposure_start_date, device_exposure_end_date ASC);
CREATE INDEX idx_measurement_sourceconcept_person ON measurement (measurement_source_concept_id,person_id,operator_concept_id, value_as_number, value_as_concept_id,measurement_date ASC);
CREATE INDEX idx_observation_sourceconcept_person ON observation (observation_source_concept_id,person_id,value_as_number, value_as_concept_id,observation_date ASC);

