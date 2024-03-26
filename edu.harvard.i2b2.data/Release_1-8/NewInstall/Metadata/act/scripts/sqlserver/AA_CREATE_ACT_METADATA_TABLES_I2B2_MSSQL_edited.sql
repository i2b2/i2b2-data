--------------------------------------------------------
--  DDL for Table COVID
--------------------------------------------------------

CREATE TABLE ACT_COVID_V41 (
        C_HLEVEL                              INT    NOT NULL,
        C_FULLNAME                    VARCHAR(700)   NOT NULL,
        C_NAME                                VARCHAR(2000)  NOT NULL,
        C_SYNONYM_CD                  CHAR(1) NOT NULL,
        C_VISUALATTRIBUTES    CHAR(3) NOT NULL,
        C_TOTALNUM                    INT    NULL,
        C_BASECODE                    VARCHAR(50)    NULL,
        C_METADATAXML                 VARCHAR(MAX)    NULL,
        C_FACTTABLECOLUMN             VARCHAR(50)    NOT NULL,
        C_TABLENAME                   VARCHAR(50)    NOT NULL,
        C_COLUMNNAME                  VARCHAR(50)    NOT NULL,
        C_COLUMNDATATYPE              VARCHAR(50)    NOT NULL,
        C_OPERATOR                    VARCHAR(10)    NOT NULL,
        C_DIMCODE                             VARCHAR(700)   NOT NULL,
        C_COMMENT                             VARCHAR(MAX)    NULL,
        C_TOOLTIP                             VARCHAR(900)   NULL,
        M_APPLIED_PATH                VARCHAR(700)   NOT NULL,
        UPDATE_DATE                   DATETIME     NULL,
        DOWNLOAD_DATE                 DATETIME    NULL,
        IMPORT_DATE                   DATETIME    NULL,
        SOURCESYSTEM_CD               VARCHAR(50)    NULL,
        VALUETYPE_CD                  VARCHAR(50)    NULL,
        M_EXCLUSION_CD                        VARCHAR(25) NULL,
        C_PATH                                VARCHAR(700)   NULL,
        C_SYMBOL                              VARCHAR(50)    NULL
)
;

--------------------------------------------------------
--  DDL for Table ACT_MED_ALPHA
--------------------------------------------------------

CREATE TABLE ACT_MED_ALPHA_V41 (
	C_HLEVEL				INT	NOT NULL, 
	C_FULLNAME			VARCHAR(700)	NOT NULL, 
	C_NAME				VARCHAR(2000)	NOT NULL, 
	C_SYNONYM_CD			CHAR(1)	NOT NULL, 
	C_VISUALATTRIBUTES	CHAR(3)	NOT NULL, 
	C_TOTALNUM			INT	NULL, 
	C_BASECODE			VARCHAR(50)	NULL, 
	C_METADATAXML			VARCHAR(MAX)	NULL, 
	C_FACTTABLECOLUMN		VARCHAR(50)	NOT NULL, 
	C_TABLENAME			VARCHAR(50)	NOT NULL, 
	C_COLUMNNAME			VARCHAR(50)	NOT NULL, 
	C_COLUMNDATATYPE		VARCHAR(50)	NOT NULL, 
	C_OPERATOR			VARCHAR(10)	NOT NULL, 
	C_DIMCODE				VARCHAR(700)	NOT NULL, 
	C_COMMENT				VARCHAR(MAX)	NULL, 
	C_TOOLTIP				VARCHAR(900)	NULL, 
	M_APPLIED_PATH		VARCHAR(700)	NOT NULL, 
	UPDATE_DATE			DATETIME	 NULL, 
	DOWNLOAD_DATE			DATETIME	NULL, 
	IMPORT_DATE			DATETIME	NULL, 
	SOURCESYSTEM_CD		VARCHAR(50)	NULL, 
	VALUETYPE_CD			VARCHAR(50)	NULL,
	M_EXCLUSION_CD			VARCHAR(25) NULL,
	C_PATH				VARCHAR(700)   NULL,
	C_SYMBOL				VARCHAR(50)	NULL
)
;
--------------------------------------------------------
--  DDL for Table ACT_MED_VA
--------------------------------------------------------

CREATE TABLE ACT_MED_VA_V41 (
        C_HLEVEL                              INT    NOT NULL,
        C_FULLNAME                    VARCHAR(700)   NOT NULL,
        C_NAME                                VARCHAR(2000)  NOT NULL,
        C_SYNONYM_CD                  CHAR(1) NOT NULL,
        C_VISUALATTRIBUTES    CHAR(3) NOT NULL,
        C_TOTALNUM                    INT    NULL,
        C_BASECODE                    VARCHAR(50)    NULL,
        C_METADATAXML                 VARCHAR(MAX)    NULL,
        C_FACTTABLECOLUMN             VARCHAR(50)    NOT NULL,
        C_TABLENAME                   VARCHAR(50)    NOT NULL,
        C_COLUMNNAME                  VARCHAR(50)    NOT NULL,
        C_COLUMNDATATYPE              VARCHAR(50)    NOT NULL,
        C_OPERATOR                    VARCHAR(10)    NOT NULL,
        C_DIMCODE                             VARCHAR(700)   NOT NULL,
        C_COMMENT                             VARCHAR(MAX)    NULL,
        C_TOOLTIP                             VARCHAR(900)   NULL,
        M_APPLIED_PATH                VARCHAR(700)   NOT NULL,
        UPDATE_DATE                   DATETIME    NULL,
        DOWNLOAD_DATE                 DATETIME    NULL,
        IMPORT_DATE                   DATETIME    NULL,
        SOURCESYSTEM_CD               VARCHAR(50)    NULL,
        VALUETYPE_CD                  VARCHAR(50)    NULL,
        M_EXCLUSION_CD                        VARCHAR(25) NULL,
        C_PATH                                VARCHAR(700)   NULL,
        C_SYMBOL                              VARCHAR(50)    NULL
)
;

--------------------------------------------------------
--  DDL for Table ACT_LOINC_LAB
--------------------------------------------------------

CREATE TABLE ACT_LOINC_LAB_V4 (
        C_HLEVEL                              INT    NOT NULL,
        C_FULLNAME                    VARCHAR(700)   NOT NULL,
        C_NAME                                VARCHAR(2000)  NOT NULL,
        C_SYNONYM_CD                  CHAR(1) NOT NULL,
        C_VISUALATTRIBUTES    CHAR(3) NOT NULL,
        C_TOTALNUM                    INT    NULL,
        C_BASECODE                    VARCHAR(50)    NULL,
        C_METADATAXML                 VARCHAR(MAX)    NULL,
        C_FACTTABLECOLUMN             VARCHAR(50)    NOT NULL,
        C_TABLENAME                   VARCHAR(50)    NOT NULL,
        C_COLUMNNAME                  VARCHAR(50)    NOT NULL,
        C_COLUMNDATATYPE              VARCHAR(50)    NOT NULL,
        C_OPERATOR                    VARCHAR(10)    NOT NULL,
        C_DIMCODE                             VARCHAR(700)   NOT NULL,
        C_COMMENT                             VARCHAR(MAX)    NULL,
        C_TOOLTIP                             VARCHAR(900)   NULL,
        M_APPLIED_PATH                VARCHAR(700)   NOT NULL,
        UPDATE_DATE                   DATETIME     NULL,
        DOWNLOAD_DATE                 DATETIME    NULL,
        IMPORT_DATE                   DATETIME    NULL,
        SOURCESYSTEM_CD               VARCHAR(50)    NULL,
        VALUETYPE_CD                  VARCHAR(50)    NULL,
        M_EXCLUSION_CD                        VARCHAR(25) NULL,
        C_PATH                                VARCHAR(700)   NULL,
        C_SYMBOL                              VARCHAR(50)    NULL
)
;

--------------------------------------------------------
--  DDL for Table ACT_LOINC_LAB
--------------------------------------------------------

CREATE TABLE ACT_LOINC_LAB_PROV_V41 (
        C_HLEVEL                              INT    NOT NULL,
        C_FULLNAME                    VARCHAR(700)   NOT NULL,
        C_NAME                                VARCHAR(2000)  NOT NULL,
        C_SYNONYM_CD                  CHAR(1) NOT NULL,
        C_VISUALATTRIBUTES    CHAR(3) NOT NULL,
        C_TOTALNUM                    INT    NULL,
        C_BASECODE                    VARCHAR(50)    NULL,
        C_METADATAXML                 VARCHAR(MAX)    NULL,
        C_FACTTABLECOLUMN             VARCHAR(50)    NOT NULL,
        C_TABLENAME                   VARCHAR(50)    NOT NULL,
        C_COLUMNNAME                  VARCHAR(50)    NOT NULL,
        C_COLUMNDATATYPE              VARCHAR(50)    NOT NULL,
        C_OPERATOR                    VARCHAR(10)    NOT NULL,
        C_DIMCODE                             VARCHAR(700)   NOT NULL,
        C_COMMENT                             VARCHAR(MAX)    NULL,
        C_TOOLTIP                             VARCHAR(900)   NULL,
        M_APPLIED_PATH                VARCHAR(700)   NOT NULL,
        UPDATE_DATE                   DATETIME    NULL,
        DOWNLOAD_DATE                 DATETIME    NULL,
        IMPORT_DATE                   DATETIME    NULL,
        SOURCESYSTEM_CD               VARCHAR(50)    NULL,
        VALUETYPE_CD                  VARCHAR(50)    NULL,
        M_EXCLUSION_CD                        VARCHAR(25) NULL,
        C_PATH                                VARCHAR(700)   NULL,
        C_SYMBOL                              VARCHAR(50)    NULL
)
;

--------------------------------------------------------
--  DDL for Table ACT_ICD09CM_PX
--------------------------------------------------------

CREATE TABLE ACT_ICD9CM_PX_V4 (
        C_HLEVEL                              INT    NOT NULL,
        C_FULLNAME                    VARCHAR(700)   NOT NULL,
        C_NAME                                VARCHAR(2000)  NOT NULL,
        C_SYNONYM_CD                  CHAR(1) NOT NULL,
        C_VISUALATTRIBUTES    CHAR(3) NOT NULL,
        C_TOTALNUM                    INT    NULL,
        C_BASECODE                    VARCHAR(50)    NULL,
        C_METADATAXML                 VARCHAR(MAX)    NULL,
        C_FACTTABLECOLUMN             VARCHAR(50)    NOT NULL,
        C_TABLENAME                   VARCHAR(50)    NOT NULL,
        C_COLUMNNAME                  VARCHAR(50)    NOT NULL,
        C_COLUMNDATATYPE              VARCHAR(50)    NOT NULL,
        C_OPERATOR                    VARCHAR(10)    NOT NULL,
        C_DIMCODE                             VARCHAR(700)   NOT NULL,
        C_COMMENT                             VARCHAR(MAX)    NULL,
        C_TOOLTIP                             VARCHAR(900)   NULL,
        M_APPLIED_PATH                VARCHAR(700)   NOT NULL,
        UPDATE_DATE                   DATETIME     NULL,
        DOWNLOAD_DATE                 DATETIME    NULL,
        IMPORT_DATE                   DATETIME    NULL,
        SOURCESYSTEM_CD               VARCHAR(50)    NULL,
        VALUETYPE_CD                  VARCHAR(50)    NULL,
        M_EXCLUSION_CD                        VARCHAR(25) NULL,
        C_PATH                                VARCHAR(700)   NULL,
        C_SYMBOL                              VARCHAR(50)    NULL
)
;

--------------------------------------------------------
--  DDL for Table ACT_ICD09CM_DX
--------------------------------------------------------

CREATE TABLE ACT_ICD9CM_DX_V4 (
        C_HLEVEL                              INT    NOT NULL,
        C_FULLNAME                    VARCHAR(700)   NOT NULL,
        C_NAME                                VARCHAR(2000)  NOT NULL,
        C_SYNONYM_CD                  CHAR(1) NOT NULL,
        C_VISUALATTRIBUTES    CHAR(3) NOT NULL,
        C_TOTALNUM                    INT    NULL,
        C_BASECODE                    VARCHAR(50)    NULL,
        C_METADATAXML                 VARCHAR(MAX)    NULL,
        C_FACTTABLECOLUMN             VARCHAR(50)    NOT NULL,
        C_TABLENAME                   VARCHAR(50)    NOT NULL,
        C_COLUMNNAME                  VARCHAR(50)    NOT NULL,
        C_COLUMNDATATYPE              VARCHAR(50)    NOT NULL,
        C_OPERATOR                    VARCHAR(10)    NOT NULL,
        C_DIMCODE                             VARCHAR(700)   NOT NULL,
        C_COMMENT                             VARCHAR(MAX)    NULL,
        C_TOOLTIP                             VARCHAR(900)   NULL,
        M_APPLIED_PATH                VARCHAR(700)   NOT NULL,
        UPDATE_DATE                   DATETIME    NULL,
        DOWNLOAD_DATE                 DATETIME    NULL,
        IMPORT_DATE                   DATETIME    NULL,
        SOURCESYSTEM_CD               VARCHAR(50)    NULL,
        VALUETYPE_CD                  VARCHAR(50)    NULL,
        M_EXCLUSION_CD                        VARCHAR(25) NULL,
        C_PATH                                VARCHAR(700)   NULL,
        C_SYMBOL                              VARCHAR(50)    NULL
)
;

--------------------------------------------------------
--  DDL for Table ACT_ICD10PCS_PX
--------------------------------------------------------

CREATE TABLE ACT_ICD10PCS_PX_V41 (
        C_HLEVEL                              INT    NOT NULL,
        C_FULLNAME                    VARCHAR(700)   NOT NULL,
        C_NAME                                VARCHAR(2000)  NOT NULL,
        C_SYNONYM_CD                  CHAR(1) NOT NULL,
        C_VISUALATTRIBUTES    CHAR(3) NOT NULL,
        C_TOTALNUM                    INT    NULL,
        C_BASECODE                    VARCHAR(50)    NULL,
        C_METADATAXML                 VARCHAR(MAX)    NULL,
        C_FACTTABLECOLUMN             VARCHAR(50)    NOT NULL,
        C_TABLENAME                   VARCHAR(50)    NOT NULL,
        C_COLUMNNAME                  VARCHAR(50)    NOT NULL,
        C_COLUMNDATATYPE              VARCHAR(50)    NOT NULL,
        C_OPERATOR                    VARCHAR(10)    NOT NULL,
        C_DIMCODE                             VARCHAR(700)   NOT NULL,
        C_COMMENT                             VARCHAR(MAX)    NULL,
        C_TOOLTIP                             VARCHAR(900)   NULL,
        M_APPLIED_PATH                VARCHAR(700)   NOT NULL,
        UPDATE_DATE                   DATETIME     NULL,
        DOWNLOAD_DATE                 DATETIME    NULL,
        IMPORT_DATE                   DATETIME    NULL,
        SOURCESYSTEM_CD               VARCHAR(50)    NULL,
        VALUETYPE_CD                  VARCHAR(50)    NULL,
        M_EXCLUSION_CD                        VARCHAR(25) NULL,
        C_PATH                                VARCHAR(700)   NULL,
        C_SYMBOL                              VARCHAR(50)    NULL
)
;

--------------------------------------------------------
--  DDL for Table ACT_ICD10CM_DX
--------------------------------------------------------

CREATE TABLE ACT_ICD10CM_DX_V41 (
        C_HLEVEL                              INT    NOT NULL,
        C_FULLNAME                    VARCHAR(700)   NOT NULL,
        C_NAME                                VARCHAR(2000)  NOT NULL,
        C_SYNONYM_CD                  CHAR(1) NOT NULL,
        C_VISUALATTRIBUTES    CHAR(3) NOT NULL,
        C_TOTALNUM                    INT    NULL,
        C_BASECODE                    VARCHAR(50)    NULL,
        C_METADATAXML                 VARCHAR(MAX)    NULL,
        C_FACTTABLECOLUMN             VARCHAR(50)    NOT NULL,
        C_TABLENAME                   VARCHAR(50)    NOT NULL,
        C_COLUMNNAME                  VARCHAR(50)    NOT NULL,
        C_COLUMNDATATYPE              VARCHAR(50)    NOT NULL,
        C_OPERATOR                    VARCHAR(10)    NOT NULL,
        C_DIMCODE                             VARCHAR(700)   NOT NULL,
        C_COMMENT                             VARCHAR(MAX)    NULL,
        C_TOOLTIP                             VARCHAR(900)   NULL,
        M_APPLIED_PATH                VARCHAR(700)   NOT NULL,
        UPDATE_DATE                   DATETIME    NULL,
        DOWNLOAD_DATE                 DATETIME    NULL,
        IMPORT_DATE                   DATETIME    NULL,
        SOURCESYSTEM_CD               VARCHAR(50)    NULL,
        VALUETYPE_CD                  VARCHAR(50)    NULL,
        M_EXCLUSION_CD                        VARCHAR(25) NULL,
        C_PATH                                VARCHAR(700)   NULL,
        C_SYMBOL                              VARCHAR(50)    NULL
)
;

--------------------------------------------------------
--  DDL for Table ACT_HCPCS_PX
--------------------------------------------------------

CREATE TABLE ACT_HCPCS_PX_V41 (
        C_HLEVEL                              INT    NOT NULL,
        C_FULLNAME                    VARCHAR(700)   NOT NULL,
        C_NAME                                VARCHAR(2000)  NOT NULL,
        C_SYNONYM_CD                  CHAR(1) NOT NULL,
        C_VISUALATTRIBUTES    CHAR(3) NOT NULL,
        C_TOTALNUM                    INT    NULL,
        C_BASECODE                    VARCHAR(50)    NULL,
        C_METADATAXML                 VARCHAR(MAX)    NULL,
        C_FACTTABLECOLUMN             VARCHAR(50)    NOT NULL,
        C_TABLENAME                   VARCHAR(50)    NOT NULL,
        C_COLUMNNAME                  VARCHAR(50)    NOT NULL,
        C_COLUMNDATATYPE              VARCHAR(50)    NOT NULL,
        C_OPERATOR                    VARCHAR(10)    NOT NULL,
        C_DIMCODE                             VARCHAR(700)   NOT NULL,
        C_COMMENT                             VARCHAR(MAX)    NULL,
        C_TOOLTIP                             VARCHAR(900)   NULL,
        M_APPLIED_PATH                VARCHAR(700)   NOT NULL,
        UPDATE_DATE                   DATETIME     NULL,
        DOWNLOAD_DATE                 DATETIME    NULL,
        IMPORT_DATE                   DATETIME    NULL,
        SOURCESYSTEM_CD               VARCHAR(50)    NULL,
        VALUETYPE_CD                  VARCHAR(50)    NULL,
        M_EXCLUSION_CD                        VARCHAR(25) NULL,
        C_PATH                                VARCHAR(700)   NULL,
        C_SYMBOL                              VARCHAR(50)    NULL
)
;

--------------------------------------------------------
--  DDL for Table ACT_CPT_PX
--------------------------------------------------------

CREATE TABLE ACT_CPT4_PX_V41 (
        C_HLEVEL                              INT    NOT NULL,
        C_FULLNAME                    VARCHAR(700)   NOT NULL,
        C_NAME                                VARCHAR(2000)  NOT NULL,
        C_SYNONYM_CD                  CHAR(1) NOT NULL,
        C_VISUALATTRIBUTES    CHAR(3) NOT NULL,
        C_TOTALNUM                    INT    NULL,
        C_BASECODE                    VARCHAR(50)    NULL,
        C_METADATAXML                 VARCHAR(MAX)    NULL,
        C_FACTTABLECOLUMN             VARCHAR(50)    NOT NULL,
        C_TABLENAME                   VARCHAR(50)    NOT NULL,
        C_COLUMNNAME                  VARCHAR(50)    NOT NULL,
        C_COLUMNDATATYPE              VARCHAR(50)    NOT NULL,
        C_OPERATOR                    VARCHAR(10)    NOT NULL,
        C_DIMCODE                             VARCHAR(700)   NOT NULL,
        C_COMMENT                             VARCHAR(MAX)    NULL,
        C_TOOLTIP                             VARCHAR(900)   NULL,
        M_APPLIED_PATH                VARCHAR(700)   NOT NULL,
        UPDATE_DATE                   DATETIME    NULL,
        DOWNLOAD_DATE                 DATETIME    NULL,
        IMPORT_DATE                   DATETIME    NULL,
        SOURCESYSTEM_CD               VARCHAR(50)    NULL,
        VALUETYPE_CD                  VARCHAR(50)    NULL,
        M_EXCLUSION_CD                        VARCHAR(25) NULL,
        C_PATH                                VARCHAR(700)   NULL,
        C_SYMBOL                              VARCHAR(50)    NULL
)
;


--------------------------------------------------------
--  DDL for Table ACT_DEMOGRAPHICS
--------------------------------------------------------

CREATE TABLE ACT_DEM_V41 (
        C_HLEVEL                              INT    NOT NULL,
        C_FULLNAME                    VARCHAR(700)   NOT NULL,
        C_NAME                                VARCHAR(2000)  NOT NULL,
        C_SYNONYM_CD                  CHAR(1) NOT NULL,
        C_VISUALATTRIBUTES    CHAR(3) NOT NULL,
        C_TOTALNUM                    INT    NULL,
        C_BASECODE                    VARCHAR(50)    NULL,
        C_METADATAXML                 VARCHAR(MAX)    NULL,
        C_FACTTABLECOLUMN             VARCHAR(50)    NOT NULL,
        C_TABLENAME                   VARCHAR(50)    NOT NULL,
        C_COLUMNNAME                  VARCHAR(50)    NOT NULL,
        C_COLUMNDATATYPE              VARCHAR(50)    NOT NULL,
        C_OPERATOR                    VARCHAR(10)    NOT NULL,
        C_DIMCODE                             VARCHAR(700)   NOT NULL,
        C_COMMENT                             VARCHAR(MAX)    NULL,
        C_TOOLTIP                             VARCHAR(900)   NULL,
        M_APPLIED_PATH                VARCHAR(700)   NOT NULL,
        UPDATE_DATE                   DATETIME     NULL,
        DOWNLOAD_DATE                 DATETIME    NULL,
        IMPORT_DATE                   DATETIME    NULL,
        SOURCESYSTEM_CD               VARCHAR(50)    NULL,
        VALUETYPE_CD                  VARCHAR(50)    NULL,
        M_EXCLUSION_CD                        VARCHAR(25) NULL,
        C_PATH                                VARCHAR(700)   NULL,
        C_SYMBOL                              VARCHAR(50)    NULL
)
;

--------------------------------------------------------
--  DDL for Table ACT_ICD10_ICD9
--------------------------------------------------------

CREATE TABLE ACT_ICD10_ICD9_DX_V4 (
        C_HLEVEL                              INT    NOT NULL,
        C_FULLNAME                    VARCHAR(700)   NOT NULL,
        C_NAME                                VARCHAR(2000)  NOT NULL,
        C_SYNONYM_CD                  CHAR(1) NOT NULL,
        C_VISUALATTRIBUTES    CHAR(3) NOT NULL,
        C_TOTALNUM                    INT    NULL,
        C_BASECODE                    VARCHAR(50)    NULL,
        C_METADATAXML                 VARCHAR(MAX)    NULL,
        C_FACTTABLECOLUMN             VARCHAR(50)    NOT NULL,
        C_TABLENAME                   VARCHAR(50)    NOT NULL,
        C_COLUMNNAME                  VARCHAR(50)    NOT NULL,
        C_COLUMNDATATYPE              VARCHAR(50)    NOT NULL,
        C_OPERATOR                    VARCHAR(10)    NOT NULL,
        C_DIMCODE                             VARCHAR(700)   NOT NULL,
        C_COMMENT                             VARCHAR(MAX)    NULL,
        C_TOOLTIP                             VARCHAR(900)   NULL,
        M_APPLIED_PATH                VARCHAR(700)   NOT NULL,
        UPDATE_DATE                   DATETIME    NULL,
        DOWNLOAD_DATE                 DATETIME    NULL,
        IMPORT_DATE                   DATETIME    NULL,
        SOURCESYSTEM_CD               VARCHAR(50)    NULL,
        VALUETYPE_CD                  VARCHAR(50)    NULL,
        M_EXCLUSION_CD                        VARCHAR(25) NULL,
        C_PATH                                VARCHAR(700)   NULL,
        C_SYMBOL                              VARCHAR(50)    NULL
)
;


--------------------------------------------------------
--  DDL for Table ACT_VISIT_DETAILS
--------------------------------------------------------

CREATE TABLE ACT_VISIT_DETAILS_V41 (
        C_HLEVEL                              INT    NOT NULL,
        C_FULLNAME                    VARCHAR(700)   NOT NULL,
        C_NAME                                VARCHAR(2000)  NOT NULL,
        C_SYNONYM_CD                  CHAR(1) NOT NULL,
        C_VISUALATTRIBUTES    CHAR(3) NOT NULL,
        C_TOTALNUM                    INT    NULL,
        C_BASECODE                    VARCHAR(50)    NULL,
        C_METADATAXML                 VARCHAR(MAX)    NULL,
        C_FACTTABLECOLUMN             VARCHAR(50)    NOT NULL,
        C_TABLENAME                   VARCHAR(50)    NOT NULL,
        C_COLUMNNAME                  VARCHAR(50)    NOT NULL,
        C_COLUMNDATATYPE              VARCHAR(50)    NOT NULL,
        C_OPERATOR                    VARCHAR(10)    NOT NULL,
        C_DIMCODE                             VARCHAR(700)   NOT NULL,
        C_COMMENT                             VARCHAR(MAX)    NULL,
        C_TOOLTIP                             VARCHAR(900)   NULL,
        M_APPLIED_PATH                VARCHAR(700)   NOT NULL,
        UPDATE_DATE                   DATETIME     NULL,
        DOWNLOAD_DATE                 DATETIME    NULL,
        IMPORT_DATE                   DATETIME    NULL,
        SOURCESYSTEM_CD               VARCHAR(50)    NULL,
        VALUETYPE_CD                  VARCHAR(50)    NULL,
        M_EXCLUSION_CD                        VARCHAR(25) NULL,
        C_PATH                                VARCHAR(700)   NULL,
        C_SYMBOL                              VARCHAR(50)    NULL
)
;


--------------------------------------------------------
--  DDL for Table ACT_SDOH
--------------------------------------------------------

CREATE TABLE ACT_SDOH_V41 (
        C_HLEVEL                              INT    NOT NULL,
        C_FULLNAME                    VARCHAR(700)   NOT NULL,
        C_NAME                                VARCHAR(2000)  NOT NULL,
        C_SYNONYM_CD                  CHAR(1) NOT NULL,
        C_VISUALATTRIBUTES    CHAR(3) NOT NULL,
        C_TOTALNUM                    INT    NULL,
        C_BASECODE                    VARCHAR(50)    NULL,
        C_METADATAXML                 VARCHAR(MAX)    NULL,
        C_FACTTABLECOLUMN             VARCHAR(50)    NOT NULL,
        C_TABLENAME                   VARCHAR(50)    NOT NULL,
        C_COLUMNNAME                  VARCHAR(50)    NOT NULL,
        C_COLUMNDATATYPE              VARCHAR(50)    NOT NULL,
        C_OPERATOR                    VARCHAR(10)    NOT NULL,
        C_DIMCODE                             VARCHAR(700)   NOT NULL,
        C_COMMENT                             VARCHAR(MAX)    NULL,
        C_TOOLTIP                             VARCHAR(900)   NULL,
        M_APPLIED_PATH                VARCHAR(700)   NOT NULL,
        UPDATE_DATE                   DATETIME    NULL,
        DOWNLOAD_DATE                 DATETIME    NULL,
        IMPORT_DATE                   DATETIME    NULL,
        SOURCESYSTEM_CD               VARCHAR(50)    NULL,
        VALUETYPE_CD                  VARCHAR(50)    NULL,
        M_EXCLUSION_CD                        VARCHAR(25) NULL,
        C_PATH                                VARCHAR(700)   NULL,
        C_SYMBOL                              VARCHAR(50)    NULL
)
;

--------------------------------------------------------
--  DDL for Table ACT_VITAL_SIGNS
--------------------------------------------------------

CREATE TABLE ACT_VITAL_SIGNS_V4 (
        C_HLEVEL                              INT    NOT NULL,
        C_FULLNAME                    VARCHAR(700)   NOT NULL,
        C_NAME                                VARCHAR(2000)  NOT NULL,
        C_SYNONYM_CD                  CHAR(1) NOT NULL,
        C_VISUALATTRIBUTES    CHAR(3) NOT NULL,
        C_TOTALNUM                    INT    NULL,
        C_BASECODE                    VARCHAR(50)    NULL,
        C_METADATAXML                 VARCHAR(MAX)    NULL,
        C_FACTTABLECOLUMN             VARCHAR(50)    NOT NULL,
        C_TABLENAME                   VARCHAR(50)    NOT NULL,
        C_COLUMNNAME                  VARCHAR(50)    NOT NULL,
        C_COLUMNDATATYPE              VARCHAR(50)    NOT NULL,
        C_OPERATOR                    VARCHAR(10)    NOT NULL,
        C_DIMCODE                             VARCHAR(700)   NOT NULL,
        C_COMMENT                             VARCHAR(MAX)    NULL,
        C_TOOLTIP                             VARCHAR(900)   NULL,
        M_APPLIED_PATH                VARCHAR(700)   NOT NULL,
        UPDATE_DATE                   DATETIME     NULL,
        DOWNLOAD_DATE                 DATETIME    NULL,
        IMPORT_DATE                   DATETIME    NULL,
        SOURCESYSTEM_CD               VARCHAR(50)    NULL,
        VALUETYPE_CD                  VARCHAR(50)    NULL,
        M_EXCLUSION_CD                        VARCHAR(25) NULL,
        C_PATH                                VARCHAR(700)   NULL,
        C_SYMBOL                              VARCHAR(50)    NULL
)
;

--------------------------------------------------------
--  DDL for Table ACT_VAX
--------------------------------------------------------

CREATE TABLE ACT_VAX_V41 (
        C_HLEVEL                              INT    NOT NULL,
        C_FULLNAME                    VARCHAR(700)   NOT NULL,
        C_NAME                                VARCHAR(2000)  NOT NULL,
        C_SYNONYM_CD                  CHAR(1) NOT NULL,
        C_VISUALATTRIBUTES    CHAR(3) NOT NULL,
        C_TOTALNUM                    INT    NULL,
        C_BASECODE                    VARCHAR(50)    NULL,
        C_METADATAXML                 VARCHAR(MAX)    NULL,
        C_FACTTABLECOLUMN             VARCHAR(50)    NOT NULL,
        C_TABLENAME                   VARCHAR(50)    NOT NULL,
        C_COLUMNNAME                  VARCHAR(50)    NOT NULL,
        C_COLUMNDATATYPE              VARCHAR(50)    NOT NULL,
        C_OPERATOR                    VARCHAR(10)    NOT NULL,
        C_DIMCODE                             VARCHAR(700)   NOT NULL,
        C_COMMENT                             VARCHAR(MAX)    NULL,
        C_TOOLTIP                             VARCHAR(900)   NULL,
        M_APPLIED_PATH                VARCHAR(700)   NOT NULL,
        UPDATE_DATE                   DATETIME     NULL,
        DOWNLOAD_DATE                 DATETIME    NULL,
        IMPORT_DATE                   DATETIME    NULL,
        SOURCESYSTEM_CD               VARCHAR(50)    NULL,
        VALUETYPE_CD                  VARCHAR(50)    NULL,
        M_EXCLUSION_CD                        VARCHAR(25) NULL,
        C_PATH                                VARCHAR(700)   NULL,
        C_SYMBOL                              VARCHAR(50)    NULL
)
;

--------------------------------------------------------
--  DDL for Table ACT_RESEARCH
--------------------------------------------------------

CREATE TABLE ACT_RESEARCH_V41 (
        C_HLEVEL                              INT    NOT NULL,
        C_FULLNAME                    VARCHAR(700)   NOT NULL,
        C_NAME                                VARCHAR(2000)  NOT NULL,
        C_SYNONYM_CD                  CHAR(1) NOT NULL,
        C_VISUALATTRIBUTES    CHAR(3) NOT NULL,
        C_TOTALNUM                    INT    NULL,
        C_BASECODE                    VARCHAR(50)    NULL,
        C_METADATAXML                 VARCHAR(MAX)    NULL,
        C_FACTTABLECOLUMN             VARCHAR(50)    NOT NULL,
        C_TABLENAME                   VARCHAR(50)    NOT NULL,
        C_COLUMNNAME                  VARCHAR(50)    NOT NULL,
        C_COLUMNDATATYPE              VARCHAR(50)    NOT NULL,
        C_OPERATOR                    VARCHAR(10)    NOT NULL,
        C_DIMCODE                             VARCHAR(700)   NOT NULL,
        C_COMMENT                             VARCHAR(MAX)    NULL,
        C_TOOLTIP                             VARCHAR(900)   NULL,
        M_APPLIED_PATH                VARCHAR(700)   NOT NULL,
        UPDATE_DATE                   DATETIME     NULL,
        DOWNLOAD_DATE                 DATETIME    NULL,
        IMPORT_DATE                   DATETIME    NULL,
        SOURCESYSTEM_CD               VARCHAR(50)    NULL,
        VALUETYPE_CD                  VARCHAR(50)    NULL,
        M_EXCLUSION_CD                        VARCHAR(25) NULL,
        C_PATH                                VARCHAR(700)   NULL,
        C_SYMBOL                              VARCHAR(50)    NULL
)
;

--------------------------------------------------------
--  DDL for Table ACT_ZIPCODE
--------------------------------------------------------

CREATE TABLE ACT_ZIPCODE_V41 (
        C_HLEVEL                              INT    NOT NULL,
        C_FULLNAME                    VARCHAR(700)   NOT NULL,
        C_NAME                                VARCHAR(2000)  NOT NULL,
        C_SYNONYM_CD                  CHAR(1) NOT NULL,
        C_VISUALATTRIBUTES    CHAR(3) NOT NULL,
        C_TOTALNUM                    INT    NULL,
        C_BASECODE                    VARCHAR(50)    NULL,
        C_METADATAXML                 VARCHAR(MAX)    NULL,
        C_FACTTABLECOLUMN             VARCHAR(50)    NOT NULL,
        C_TABLENAME                   VARCHAR(50)    NOT NULL,
        C_COLUMNNAME                  VARCHAR(50)    NOT NULL,
        C_COLUMNDATATYPE              VARCHAR(50)    NOT NULL,
        C_OPERATOR                    VARCHAR(10)    NOT NULL,
        C_DIMCODE                             VARCHAR(700)   NOT NULL,
        C_COMMENT                             VARCHAR(MAX)    NULL,
        C_TOOLTIP                             VARCHAR(900)   NULL,
        M_APPLIED_PATH                VARCHAR(700)   NOT NULL,
        UPDATE_DATE                   DATETIME     NULL,
        DOWNLOAD_DATE                 DATETIME    NULL,
        IMPORT_DATE                   DATETIME    NULL,
        SOURCESYSTEM_CD               VARCHAR(50)    NULL,
        VALUETYPE_CD                  VARCHAR(50)    NULL,
        M_EXCLUSION_CD                        VARCHAR(25) NULL,
        C_PATH                                VARCHAR(700)   NULL,
        C_SYMBOL                              VARCHAR(50)    NULL
)
;

