CREATE TABLE XXOEM.XXOEM_PAY_RECIBO_PERCEPCIONES2
--P    TipoPercepcion    Clave    Concepto    ImporteGravado    ImporteExento
--num_linea--concepto
(
  RECIBO_ID             NUMBER,
  NUM_LINEA             NUMBER,                --Clave 
  CONCEPTO              VARCHAR2(80 BYTE),     --Concepto
  IMPORTE               VARCHAR2(13 BYTE),
  IMPORTE_PERCEPCIONES  NUMBER,
  ELEMENT_TYPE_ID       NUMBER(9)               NOT NULL,--TipoPercepcion
  DIAS                  NUMBER,
  ImporteGravado number,
  ImporteExento number,
  atributte_1 varchar(100),
  atributte_2 varchar(100),
  atributte_3 varchar(100),
  atributte_4 varchar(100),
  atributte_5 varchar(100)
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
GRANT ALTER, DELETE, INDEX, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON XXOEM.XXOEM_PAY_RECIBO_PERCEPCIONES2 TO APPS;
/