update i2b2
set c_dimcode =  '((select birth_date from i2b2demodata.dbo.patient_dimension where patient_num = i2b2demodata.dbo.visit_dimension.patient_num) + (365.25 * 80)-1) AND ((select birth_date from i2b2demodata.dbo.patient_dimension where patient_num = i2b2demodata.dbo.visit_dimension.patient_num) + (365.25 * 81)-1)'
where c_fullname = '\i2b2\Visit Details\Age at visit\>= 65 years old\80\';
update i2b2
set c_dimcode =  '((select birth_date from i2b2demodata.dbo.patient_dimension where patient_num = i2b2demodata.dbo.visit_dimension.patient_num) + (365.25 * 81)-1) AND ((select birth_date from i2b2demodata.dbo.patient_dimension where patient_num = i2b2demodata.dbo.visit_dimension.patient_num) + (365.25 * 82)-1)'
where c_fullname = '\i2b2\Visit Details\Age at visit\>= 65 years old\81\';
update i2b2 
set c_dimcode = '((select birth_date from i2b2demodata.dbo.patient_dimension where patient_num = i2b2demodata.dbo.visit_dimension.patient_num) + (365.25 * 24)-1) AND ((select birth_date from i2b2demodata.dbo.patient_dimension where patient_num = i2b2demodata.dbo.visit_dimension.patient_num) + (365.25 * 25)-1)'
where c_fullname = '\i2b2\Visit Details\Age at visit\18-34 years old\24 years old\';
update i2b2
set c_dimcode = '((select birth_date from i2b2demodata.dbo.patient_dimension where patient_num = i2b2demodata.dbo.visit_dimension.patient_num) + (365.25 * 89)-1) AND ((select birth_date from i2b2demodata.dbo.patient_dimension where patient_num = i2b2demodata.dbo.visit_dimension.patient_num) + (365.25 * 90)-1)'
where c_fullname = '\i2b2\Visit Details\Age at visit\>= 65 years old\89\';
