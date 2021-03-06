DROP SEQUENCE XXOEM.XXOEM_PAY_RECIBOS_S2;

CREATE SEQUENCE XXOEM.XXOEM_PAY_RECIBOS_S2
  START WITH 1
  MAXVALUE 999999999999999999999999999
  MINVALUE 1
  NOCYCLE
  CACHE 20
  NOORDER;


GRANT ALTER, SELECT ON XXOEM.XXOEM_PAY_RECIBOS_S2 TO APPS;

-------------------
CREATE TABLE XXOEM.XXOEM_PAY_RECIBO_EXTRAS2
(
  RECIBO_ID             NUMBER,
  NUM_LINEA             NUMBER,
  CONCEPTO              VARCHAR2(80 BYTE),---- tipo incapacidad
  IMPORTE_PAGADO   NUMBER,                -----IMPORTE_PAGADO
  --IMPORTE               VARCHAR2(13 BYTE),
  --IMPORTE_PERCEPCIONES  NUMBER,
  ELEMENT_TYPE_ID       NUMBER(9)               NOT NULL,-------
  HORAS_EXTRAS          NUMBER,--   HORAS EXTRAS
  DIAS_EXTRAS          NUMBER,----CALCULO DE DIAS DEPENDIENDO DE LAS HORAS
  segment1           VARCHAR2(100 BYTE),
  segment2           VARCHAR2(100 BYTE),
  segment3           VARCHAR2(100 BYTE),
  segment4           VARCHAR2(100 BYTE),
  segment5           VARCHAR2(100 BYTE)
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

CREATE PUBLIC SYNONYM XXOEM_PAY_RECIBO_EXTRAS2 FOR XXOEM.XXOEM_PAY_RECIBO_EXTRAS2;

/
CREATE TABLE XXOEM.XXOEM_PAY_RECIBO_indem2
(
  RECIBO_ID             NUMBER,
  NUM_LINEA             NUMBER,
  CONCEPTO              VARCHAR2(80 BYTE),---- tipo incapacidad
  IMPORTE               VARCHAR2(13 BYTE),----- imporyte incapacidad
  IMPORTE_PERCEPCIONES  NUMBER,
  ELEMENT_TYPE_ID       NUMBER(9)               NOT NULL,-------
  DIAS                  NUMBER,--   dias incapacidad
  segment1           VARCHAR2(100 BYTE),
  segment2           VARCHAR2(100 BYTE),
  segment3           VARCHAR2(100 BYTE),
  segment4           VARCHAR2(100 BYTE),
  segment5           VARCHAR2(100 BYTE)
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

CREATE PUBLIC SYNONYM XXOEM_PAY_RECIBO_indem2 FOR XXOEM.XXOEM_PAY_RECIBO_indem2;


GRANT ALTER, DELETE, INDEX, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON XXOEM.XXOEM_PAY_RECIBO_indem2 TO APPS;


/
DROP TABLE XXOEM.XXOEM_PAY_RECIBO_PERCEPCIONES2 CASCADE CONSTRAINTS;

CREATE TABLE XXOEM.XXOEM_PAY_RECIBO_PERCEPCIONES2
(
  RECIBO_ID             NUMBER,
  NUM_LINEA             NUMBER,
  --CONCEPTO              VARCHAR2(80 BYTE),
  CLAVE varchar2(15),
  TIPO_PERCEPCION VARCHAR2(100),
  DESCRIPCION VARCHAR2(100),
  IMPORTE               VARCHAR2(13 BYTE),
  IMPORTE_PERCEPCIONES  NUMBER,
  ELEMENT_TYPE_ID       NUMBER(9)               NOT NULL,
  DIAS                  NUMBER,
  IMPORTEGRAVADO        NUMBER,
  IMPORTEEXENTO         NUMBER,
  segment1           VARCHAR2(100 BYTE),
  segment2           VARCHAR2(100 BYTE),
  segment3           VARCHAR2(100 BYTE),
  segment4           VARCHAR2(100 BYTE),
  segment5           VARCHAR2(100 BYTE)
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
DROP TABLE XXOEM.XXOEM_PAY_RECIBO_DEDUCCIONES2 CASCADE CONSTRAINTS;

CREATE TABLE XXOEM.XXOEM_PAY_RECIBO_DEDUCCIONES2
(
  RECIBO_ID            NUMBER,
  NUM_LINEA            NUMBER,
  CONCEPTO             VARCHAR2(80 BYTE),
  IMPORTE              VARCHAR2(13 BYTE),
  IMPORTE_DEDUCCIONES  NUMBER,
  ELEMENT_TYPE_ID      NUMBER(9)                NOT NULL,
  DIAS                 NUMBER,
  IMPORTEGRAVADO       NUMBER,
  IMPORTEEXENTO        NUMBER,
  segment1          VARCHAR2(100 BYTE),
  segment2          VARCHAR2(100 BYTE),
  segment3          VARCHAR2(100 BYTE),
  segment4          VARCHAR2(100 BYTE),
  segment5          VARCHAR2(100 BYTE)
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

CREATE TABLE XXOEM.XXOEM_PAY_MAESTRO_RECIBOS2
(recibo_id number,---enlasa tablas
  ID_NOMINA               NUMBER,
  numero_empleado         VARCHAR2(30 BYTE),                 ----requerido
  fecha_pago           DATE,
  fecha_inicial              DATE                  NOT NULL,
  fecha_final            DATE,
  dias_pagados   NUMBER,
  salario_Base_Cot NUMBER,
  SDI NUMBER,
  decripcion VARCHAR(100),
  FULL_NAME               VARCHAR2(240 BYTE),
  TIME_PERIOD_ID          NUMBER(15)            NOT NULL,
  PERSON_ID               NUMBER(10)            NOT NULL,    ----requerido
  DEPARTAMENTO            VARCHAR2(240 BYTE),                ----requerido
  ELEMENT_SET_ID          NUMBER(9),                         ----requerido
  LOCATION_CODE           VARCHAR2(60 BYTE),                  ----requerido   
  PAYROLL_ACTION_ID       NUMBER(9)             NOT NULL,      ----requerid
  DIVISION                VARCHAR2(60 BYTE),                     ----requerido
  CENTRO_COSTOS           VARCHAR2(60 BYTE),                     ----requerido 
  SEGMENT1 VARCHAR2(60 BYTE),
  SEGMENT2 VARCHAR2(60 BYTE),
  SEGMENT3 VARCHAR2(60 BYTE),
  SEGMENT4 VARCHAR2(60 BYTE),
  SEGMENT5 VARCHAR2(60 BYTE)
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


DROP PUBLIC SYNONYM XXOEM_PAY_MAESTRO_RECIBOS2;

CREATE PUBLIC SYNONYM XXOEM_PAY_MAESTRO_RECIBOS2 FOR XXOEM.XXOEM_PAY_MAESTRO_RECIBOS2;


GRANT ALTER, DELETE, INDEX, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON XXOEM.XXOEM_PAY_MAESTRO_RECIBOS2 TO APPS;

