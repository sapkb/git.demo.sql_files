DROP TABLE XXOEM.XXOEM_PAY_MAESTRO_RECIBOS2

CREATE TABLE XXOEM.XXOEM_PAY_MAESTRO_RECIBOS2
--tipo    IdNomina    NumEmpleado    FechaPago    
--FechaInicialPago    FechaFinalPago    NumDiasPagados    
--SalarioBaseCotApor    SalarioDiarioIntegrado    Descripcion
(
  RECIBO_ID               NUMBER,
  RECIBO_NUM              VARCHAR2(10 BYTE)     NOT NULL,
  CREATION_DATE           DATE,                          --FechaPago
  PAYROLL_ID              NUMBER(9)             NOT NULL,--id_nomina
  PAYROLL_NAME            VARCHAR2(80 BYTE)     NOT NULL,--nomina
  --PERSON_ID               NUMBER(10)            NOT NULL, 
  EMPLOYEE_NUMBER         VARCHAR2(30 BYTE),             --NumEmpleado
  --FULL_NAME               VARCHAR2(240 BYTE),
  --TIME_PERIOD_ID          NUMBER(15)            NOT NULL,
  --PERIOD_NAME             VARCHAR2(70 BYTE)     NOT NULL,
--  RFC                     VARCHAR2(150 BYTE),
--  IMSS                    VARCHAR2(150 BYTE),
--  CURP                    VARCHAR2(30 BYTE),
--  DEPARTAMENTO            VARCHAR2(240 BYTE),
--  PUESTO                  VARCHAR2(60 BYTE),
--  COMPANIA                VARCHAR2(150 BYTE),
--  RFC_CIA                 VARCHAR2(150 BYTE),
--  PAY_BASIS_ID            NUMBER(9),
--  GRADE_ID                NUMBER(15),
--  ASSIGNMENT_ID           NUMBER(10)            NOT NULL,
  START_DATE              DATE                  NOT NULL, --FechaInicialPago
  CUT_OFF_DATE            DATE,                           --FechaFinalPago
--  ELEMENT_SET_ID          NUMBER(9),
--  ASSIGNMENT_ACTION_ID    NUMBER(15)            NOT NULL,
--  LOCATION_CODE           VARCHAR2(60 BYTE),
  PAYROLL_ACTION_ID       NUMBER(9)             NOT NULL,
--  PER_INI                 VARCHAR2(2 BYTE),
--  PER_FIN                 VARCHAR2(11 BYTE),
--  PERIOD_NUM              NUMBER(15)            NOT NULL,
--  DIVISION                VARCHAR2(60 BYTE),
--  CENTRO_COSTOS           VARCHAR2(60 BYTE),
--  DEPTO                   VARCHAR2(60 BYTE),
--  SOFT_CODING_KEYFLEX_ID  NUMBER(15)
numdiaspagados number,
SalarioBaseCotApor number,    
SalarioDiarioIntegrado  number,  
Descripcion varchar2(100),
atributte_1 varchar2(100),
atributte_2 varchar2(100),
atributte_3 varchar2(100),
atributte_4 varchar2(100),
atributte_5 varchar2(100)
)
TABLESPACE XXOEM
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            NEXT             1M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING 
NOCOMPRESS 
NOCACHE
NOPARALLEL
MONITORING;
/
GRANT ALTER, DELETE, INDEX, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON XXOEM.XXOEM_PAY_MAESTRO_RECIBOS2 TO APPS;
/