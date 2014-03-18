DROP TABLE XXOEM.XXOEM_PAY_RECIBO_PERCEPCIONES2 CASCADE CONSTRAINTS;

CREATE TABLE XXOEM.XXOEM_PAY_RECIBO_PERCEPCIONES2
(
  RECIBO_ID             NUMBER,
  NUM_LINEA             NUMBER,
  CONCEPTO              VARCHAR2(80 BYTE),
  IMPORTE               VARCHAR2(13 BYTE),
  IMPORTE_PERCEPCIONES  NUMBER,
  ELEMENT_TYPE_ID       NUMBER(9)               NOT NULL,
  DIAS                  NUMBER,
  IMPORTEGRAVADO        NUMBER,
  IMPORTEEXENTO         NUMBER,
  ATRIBUTTE_1           VARCHAR2(100 BYTE),
  ATRIBUTTE_2           VARCHAR2(100 BYTE),
  ATRIBUTTE_3           VARCHAR2(100 BYTE),
  ATRIBUTTE_4           VARCHAR2(100 BYTE),
  ATRIBUTTE_5           VARCHAR2(100 BYTE)
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


DROP PUBLIC SYNONYM XXOEM_PAY_RECIBO_PERCEPCIONES2;

CREATE PUBLIC SYNONYM XXOEM_PAY_RECIBO_PERCEPCIONES2 FOR XXOEM.XXOEM_PAY_RECIBO_PERCEPCIONES2;


GRANT ALTER, DELETE, INDEX, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON XXOEM.XXOEM_PAY_RECIBO_PERCEPCIONES2 TO APPS;

