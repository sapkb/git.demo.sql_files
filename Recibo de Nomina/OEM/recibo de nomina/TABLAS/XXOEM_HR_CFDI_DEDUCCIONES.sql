CREATE TABLE XXOEM.XXOEM_HR_CFDI_DEDUCCIONES 
(
RECIBO_ID NUMBER,
NUM_LINEA NUMBER,
CLAVE_DED VARCHAR2(15),
ELEMENT_TYPE_ID NUMBER,
DIAS_DED NUMBER,
GRAVADO_DED NUMBER,
EXENTO_DED NUMBER,
TIPO_DED VARCHAR2(1000),
DESCRIPCION_DED VARCHAR(1000),
ID_DATOS VARCHAR(1)
                  );
/
GRANT ALL ON XXOEM.XXOEM_HR_CFDI_DEDUCCIONES TO APPS;
/