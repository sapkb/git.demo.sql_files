CREATE TABLE XXOEM.XXOEM_HR_CFDI_HORASEXTRAS (   RECIBO_ID NUMBER,
                                                                   NUM_LINEA NUMBER,
                                                                   TIPO_HORAS VARCHAR2(20),
                                                                   IMPORTE_PAGADO NUMBER,
                                                                   ELEMENT_TYPE_ID NUMBER,
                                                                   HORAS_EXTRAS NUMBER,
                                                                   DIAS_EXTRAS NUMBER,
                                                                   ID_DATOS VARCHAR2(1)                                                                   
                          );
/
GRANT ALL ON XXOEM_HR_CFDI_HORASEXTRAS TO APPS;
 /                                  