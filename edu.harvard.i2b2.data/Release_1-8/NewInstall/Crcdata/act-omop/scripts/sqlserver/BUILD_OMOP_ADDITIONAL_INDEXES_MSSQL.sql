-- Additional indexes on OMOP tables to optimize for i2b2 cohort queries.
-- Written by Jeff Klann, Darren Henderson, and Griffin Weber

-- Index concept_id, person_id
CREATE INDEX idx_visit_concept_person_1 ON visit_occurrence (visit_concept_id,person_id ASC) include(visit_start_date, visit_end_date);
--CREATE INDEX idx_visit_det_concept_person_1 ON visit_detail (visit_detail_concept_id,person_id ASC) include(visit_detail_start_date, visit_detail_end_date);
CREATE INDEX idx_condition_concept_person_1 ON condition_occurrence (condition_concept_id,person_id ASC) include(condition_start_date, condition_end_date);
CREATE INDEX idx_drug_concept_person_1 ON drug_exposure (drug_concept_id,person_id ASC) include(drug_exposure_start_date, drug_exposure_end_date);
CREATE INDEX idx_procedure_concept_person_1 ON procedure_occurrence (procedure_concept_id,person_id ASC) include(procedure_date, procedure_end_date);
CREATE INDEX idx_device_concept_person_1 ON device_exposure (device_concept_id,person_id ASC) include(device_exposure_start_date, device_exposure_end_date);
CREATE INDEX idx_measurement_concept_person_1 ON measurement (measurement_concept_id,person_id ASC) include(operator_concept_id, value_as_number, value_as_concept_id,measurement_date);
CREATE INDEX idx_observation_concept_person_1 ON observation (observation_concept_id,person_id ASC) include(value_as_number, value_as_concept_id,observation_date);


-- Index source_concept_id, person_id
CREATE INDEX idx_visit_sourceconcept_person ON visit_occurrence (visit_source_concept_id,person_id ASC) include(visit_start_date, visit_end_date);
--CREATE INDEX idx_visit_det_sourceconcept_person ON visit_detail (visit_detail_source_concept_id,person_id ASC) include(visit_detail_start_date, visit_detail_end_date);
CREATE INDEX idx_condition_sourceconcept_person ON condition_occurrence (condition_source_concept_id,person_id ASC) include(condition_start_date, condition_end_date);
CREATE INDEX idx_drug_sourceconcept_person ON drug_exposure (drug_source_concept_id,person_id ASC) include(drug_exposure_start_date, drug_exposure_end_date);
CREATE INDEX idx_procedure_sourceconcept_person ON procedure_occurrence (procedure_source_concept_id,person_id ASC) include(procedure_date, procedure_end_date);
CREATE INDEX idx_device_sourceconcept_person ON device_exposure (device_source_concept_id,person_id ASC) include(device_exposure_start_date, device_exposure_end_date);
CREATE INDEX idx_measurement_sourceconcept_person ON measurement (measurement_source_concept_id,person_id ASC) include(operator_concept_id, value_as_number, value_as_concept_id,measurement_date);
CREATE INDEX idx_observation_sourceconcept_person ON observation (observation_source_concept_id,person_id ASC) include(value_as_number, value_as_concept_id,observation_date);

/* The includes() are for query-by-value. To support same-visit queries, one would need to add a parallel set of indexes on concept_id, visit_id. 
   The start_date, end_date in the includes support date constraints but make the indexes much bigger, so remove them if you don't need that feature. */


/* Version that does include only for person, not good for patient-set queries and seems to be the same size
CREATE INDEX idx_visit_concept_person_1 ON visit_occurrence (visit_concept_id ASC) include(person_id);
CREATE INDEX idx_visit_det_concept_person_1 ON visit_detail (visit_detail_concept_id ASC) include(person_id);
CREATE INDEX idx_condition_concept_person_1 ON condition_occurrence (condition_concept_id ASC) include(person_id);
CREATE INDEX idx_drug_concept_person_1 ON drug_exposure (drug_concept_id ASC) include(person_id);
CREATE INDEX idx_procedure_concept_person_1 ON procedure_occurrence (procedure_concept_id ASC) include(person_id);
CREATE INDEX idx_device_concept_person_1 ON device_exposure (device_concept_id ASC) include(person_id);
CREATE INDEX idx_measurement_concept_person_1 ON measurement (measurement_concept_id ASC) include(person_id, operator_concept_id, value_as_number, value_as_concept_id);
CREATE INDEX idx_observation_concept_person_1 ON observation (observation_concept_id ASC) include(person_id, value_as_number, value_as_concept_id);
CREATE INDEX idx_note_concept_person_1 ON note (note_type_concept_id ASC) include(person_id);
CREATE INDEX idx_specimen_concept_person_1 ON specimen (specimen_concept_id ASC) include(person_id);
*/


