CREATE INDEX META_EXC_ACT_COVID_V41 ON ACT_COVID_V41(M_EXCLUSION_CD);
CREATE INDEX META_EXC_ACT_CPT4_PX_V41 ON ACT_CPT4_PX_V41(M_EXCLUSION_CD);
CREATE INDEX META_EXC_ACT_DEM_V41 ON ACT_DEM_V41(M_EXCLUSION_CD);
CREATE INDEX META_EXC_ACT_HCPCS_PX_V41 ON ACT_HCPCS_PX_V41(M_EXCLUSION_CD);
CREATE INDEX META_EXC_ACT_ICD10CM_DX_V41 ON ACT_ICD10CM_DX_V41(M_EXCLUSION_CD);
CREATE INDEX META_EXC_ACT_ICD10PCS_PX_V41 ON ACT_ICD10PCS_PX_V41(M_EXCLUSION_CD);
CREATE INDEX META_EXC_ACT_ICD10_ICD9_DX_V4 ON ACT_ICD10_ICD9_DX_V4(M_EXCLUSION_CD);
CREATE INDEX META_EXC_ACT_ICD9CM_DX_V4 ON ACT_ICD9CM_DX_V4(M_EXCLUSION_CD);
CREATE INDEX META_EXC_ACT_ICD9CM_PX_V4 ON ACT_ICD9CM_PX_V4(M_EXCLUSION_CD);
CREATE INDEX META_EXC_ACT_LOINC_LAB_PROV_V41 ON ACT_LOINC_LAB_PROV_V41(M_EXCLUSION_CD);
CREATE INDEX META_EXC_ACT_LOINC_LAB_V4 ON ACT_LOINC_LAB_V4(M_EXCLUSION_CD);
CREATE INDEX META_EXC_ACT_MED_ALPHA_V41 ON ACT_MED_ALPHA_V41(M_EXCLUSION_CD);
CREATE INDEX META_EXC_ACT_MED_VA_V41 ON ACT_MED_VA_V41(M_EXCLUSION_CD);
CREATE INDEX META_EXC_ACT_RESEARCH_V41 ON ACT_RESEARCH_V41(M_EXCLUSION_CD);
CREATE INDEX META_EXC_ACT_SDOH_V41 ON ACT_SDOH_V41(M_EXCLUSION_CD);
CREATE INDEX META_EXC_ACT_VAX_V41 ON ACT_VAX_V41(M_EXCLUSION_CD);
CREATE INDEX META_EXC_ACT_VISIT_DETAILS_V41 ON ACT_VISIT_DETAILS_V41(M_EXCLUSION_CD);
CREATE INDEX META_EXC_ACT_VITAL_SIGNS_V4 ON ACT_VITAL_SIGNS_V4(M_EXCLUSION_CD);
CREATE INDEX META_EXC_ACT_ZIPCODE_V41 ON ACT_ZIPCODE_V41(M_EXCLUSION_CD);

CREATE INDEX META_FN_ACT_COVID_V41 ON ACT_COVID_V41(C_FULLNAME);
CREATE INDEX META_FN_ACT_CPT4_PX_V41 ON ACT_CPT4_PX_V41(C_FULLNAME);
CREATE INDEX META_FN_ACT_DEM_V41 ON ACT_DEM_V41(C_FULLNAME);
CREATE INDEX META_FN_ACT_HCPCS_PX_V41 ON ACT_HCPCS_PX_V41(C_FULLNAME);
CREATE INDEX META_FN_ACT_ICD10CM_DX_V41 ON ACT_ICD10CM_DX_V41(C_FULLNAME);
CREATE INDEX META_FN_ACT_ICD10PCS_PX_V41 ON ACT_ICD10PCS_PX_V41(C_FULLNAME);
CREATE INDEX META_FN_ACT_ICD10_ICD9_DX_V4 ON ACT_ICD10_ICD9_DX_V4(C_FULLNAME);
CREATE INDEX META_FN_ACT_ICD9CM_DX_V4 ON ACT_ICD9CM_DX_V4(C_FULLNAME);
CREATE INDEX META_FN_ACT_ICD9CM_PX_V4 ON ACT_ICD9CM_PX_V4(C_FULLNAME);
CREATE INDEX META_FN_ACT_LOINC_LAB_PROV_V41 ON ACT_LOINC_LAB_PROV_V41(C_FULLNAME);
CREATE INDEX META_FN_ACT_LOINC_LAB_V4 ON ACT_LOINC_LAB_V4(C_FULLNAME);
CREATE INDEX META_FN_ACT_MED_ALPHA_V41 ON ACT_MED_ALPHA_V41(C_FULLNAME);
CREATE INDEX META_FN_ACT_MED_VA_V41 ON ACT_MED_VA_V41(C_FULLNAME);
CREATE INDEX META_FN_ACT_RESEARCH_V41 ON ACT_RESEARCH_V41(C_FULLNAME);
CREATE INDEX META_FN_ACT_SDOH_V41 ON ACT_SDOH_V41(C_FULLNAME);
CREATE INDEX META_FN_ACT_VAX_V41 ON ACT_VAX_V41(C_FULLNAME);
CREATE INDEX META_FN_ACT_VISIT_DETAILS_V41 ON ACT_VISIT_DETAILS_V41(C_FULLNAME);

CREATE INDEX META_FN_ACT_VITAL_SIGNS_V4 ON ACT_VITAL_SIGNS_V4(C_FULLNAME);
CREATE INDEX META_FN_ACT_ZIPCODE_V41 ON ACT_ZIPCODE_V41(C_FULLNAME);
CREATE INDEX META_LVL_ACT_COVID_V41 ON ACT_COVID_V41(C_HLEVEL);
CREATE INDEX META_LVL_ACT_CPT4_PX_V41 ON ACT_CPT4_PX_V41(C_HLEVEL);
CREATE INDEX META_LVL_ACT_DEM_V41 ON ACT_DEM_V41(C_HLEVEL);
CREATE INDEX META_LVL_ACT_HCPCS_PX_V41 ON ACT_HCPCS_PX_V41(C_HLEVEL);
CREATE INDEX META_LVL_ACT_ICD10CM_DX_V41 ON ACT_ICD10CM_DX_V41(C_HLEVEL);
CREATE INDEX META_LVL_ACT_ICD10PCS_PX_V41 ON ACT_ICD10PCS_PX_V41(C_HLEVEL);
CREATE INDEX META_LVL_ACT_ICD10_ICD9_DX_V4 ON ACT_ICD10_ICD9_DX_V4(C_HLEVEL);
CREATE INDEX META_LVL_ACT_ICD9CM_DX_V4 ON ACT_ICD9CM_DX_V4(C_HLEVEL);
CREATE INDEX META_LVL_ACT_ICD9CM_PX_V4 ON ACT_ICD9CM_PX_V4(C_HLEVEL);
CREATE INDEX META_LVL_ACT_LOINC_LAB_PROV_V41 ON ACT_LOINC_LAB_PROV_V41(C_HLEVEL);
CREATE INDEX META_LVL_ACT_LOINC_LAB_V4 ON ACT_LOINC_LAB_V4(C_HLEVEL);
CREATE INDEX META_LVL_ACT_MED_ALPHA_V41 ON ACT_MED_ALPHA_V41(C_HLEVEL);
CREATE INDEX META_LVL_ACT_MED_VA_V41 ON ACT_MED_VA_V41(C_HLEVEL);
CREATE INDEX META_LVL_ACT_RESEARCH_V41 ON ACT_RESEARCH_V41(C_HLEVEL);
CREATE INDEX META_LVL_ACT_SDOH_V41 ON ACT_SDOH_V41(C_HLEVEL);
CREATE INDEX META_LVL_ACT_VAX_V41 ON ACT_VAX_V41(C_HLEVEL);
CREATE INDEX META_LVL_ACT_VISIT_DETAILS_V41 ON ACT_VISIT_DETAILS_V41(C_HLEVEL);
CREATE INDEX META_LVL_ACT_VITAL_SIGNS_V4 ON ACT_VITAL_SIGNS_V4(C_HLEVEL);
CREATE INDEX META_LVL_ACT_ZIPCODE_V41 ON ACT_ZIPCODE_V41(C_HLEVEL);

CREATE INDEX META_PATH_ACT_COVID_V41 ON ACT_COVID_V41(M_APPLIED_PATH);
CREATE INDEX META_PATH_ACT_CPT4_PX_V41 ON ACT_CPT4_PX_V41(M_APPLIED_PATH);
CREATE INDEX META_PATH_ACT_DEM_V41 ON ACT_DEM_V41(M_APPLIED_PATH);
CREATE INDEX META_PATH_ACT_HCPCS_PX_V41 ON ACT_HCPCS_PX_V41(M_APPLIED_PATH);
CREATE INDEX META_PATH_ACT_ICD10CM_DX_V41 ON ACT_ICD10CM_DX_V41(M_APPLIED_PATH);
CREATE INDEX META_PATH_ACT_ICD10PCS_PX_V41 ON ACT_ICD10PCS_PX_V41(M_APPLIED_PATH);
CREATE INDEX META_PATH_ACT_ICD10_ICD9_DX_V4 ON ACT_ICD10_ICD9_DX_V4(M_APPLIED_PATH);
CREATE INDEX META_PATH_ACT_ICD9CM_DX_V4 ON ACT_ICD9CM_DX_V4(M_APPLIED_PATH);
CREATE INDEX META_PATH_ACT_ICD9CM_PX_V4 ON ACT_ICD9CM_PX_V4(M_APPLIED_PATH);
CREATE INDEX META_PATH_ACT_LOINC_LAB_PROV_V41 ON ACT_LOINC_LAB_PROV_V41(M_APPLIED_PATH);
CREATE INDEX META_PATH_ACT_LOINC_LAB_V4 ON ACT_LOINC_LAB_V4(M_APPLIED_PATH);
CREATE INDEX META_PATH_ACT_MED_ALPHA_V41 ON ACT_MED_ALPHA_V41(M_APPLIED_PATH);
CREATE INDEX META_PATH_ACT_MED_VA_V41 ON ACT_MED_VA_V41(M_APPLIED_PATH);
CREATE INDEX META_PATH_ACT_RESEARCH_V41 ON ACT_RESEARCH_V41(M_APPLIED_PATH);
CREATE INDEX META_PATH_ACT_SDOH_V41 ON ACT_SDOH_V41(M_APPLIED_PATH);
CREATE INDEX META_PATH_ACT_VAX_V41 ON ACT_VAX_V41(M_APPLIED_PATH);
CREATE INDEX META_PATH_ACT_VISIT_DETAILS_V41 ON ACT_VISIT_DETAILS_V41(M_APPLIED_PATH);
CREATE INDEX META_PATH_ACT_VITAL_SIGNS_V4 ON ACT_VITAL_SIGNS_V4(M_APPLIED_PATH);
CREATE INDEX META_PATH_ACT_ZIPCODE_V41 ON ACT_ZIPCODE_V41(M_APPLIED_PATH);

CREATE INDEX META_SYN_ACT_COVID_V41 ON ACT_COVID_V41(C_SYNONYM_CD);
CREATE INDEX META_SYN_ACT_CPT4_PX_V41 ON ACT_CPT4_PX_V41(C_SYNONYM_CD);
CREATE INDEX META_SYN_ACT_DEM_V41 ON ACT_DEM_V41(C_SYNONYM_CD);
CREATE INDEX META_SYN_ACT_HCPCS_PX_V41 ON ACT_HCPCS_PX_V41(C_SYNONYM_CD);
CREATE INDEX META_SYN_ACT_ICD10CM_DX_V41 ON ACT_ICD10CM_DX_V41(C_SYNONYM_CD);
CREATE INDEX META_SYN_ACT_ICD10PCS_PX_V41 ON ACT_ICD10PCS_PX_V41(C_SYNONYM_CD);
CREATE INDEX META_SYN_ACT_ICD10_ICD9_DX_V4 ON ACT_ICD10_ICD9_DX_V4(C_SYNONYM_CD);
CREATE INDEX META_SYN_ACT_ICD9CM_DX_V4 ON ACT_ICD9CM_DX_V4(C_SYNONYM_CD);
CREATE INDEX META_SYN_ACT_ICD9CM_PX_V4 ON ACT_ICD9CM_PX_V4(C_SYNONYM_CD);
CREATE INDEX META_SYN_ACT_LOINC_LAB_PROV_V41 ON ACT_LOINC_LAB_PROV_V41(C_SYNONYM_CD);
CREATE INDEX META_SYN_ACT_LOINC_LAB_V4 ON ACT_LOINC_LAB_V4(C_SYNONYM_CD);
CREATE INDEX META_SYN_ACT_MED_ALPHA_V41 ON ACT_MED_ALPHA_V41(C_SYNONYM_CD);
CREATE INDEX META_SYN_ACT_MED_VA_V41 ON ACT_MED_VA_V41(C_SYNONYM_CD);
CREATE INDEX META_SYN_ACT_RESEARCH_V41 ON ACT_RESEARCH_V41(C_SYNONYM_CD);
CREATE INDEX META_SYN_ACT_SDOH_V41 ON ACT_SDOH_V41(C_SYNONYM_CD);
CREATE INDEX META_SYN_ACT_VAX_V41 ON ACT_VAX_V41(C_SYNONYM_CD);
CREATE INDEX META_SYN_ACT_VISIT_DETAILS_V41 ON ACT_VISIT_DETAILS_V41(C_SYNONYM_CD);
CREATE INDEX META_SYN_ACT_VITAL_SIGNS_V4 ON ACT_VITAL_SIGNS_V4(C_SYNONYM_CD);