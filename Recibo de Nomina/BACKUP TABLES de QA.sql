/* TABLAS A RESPALDAR */
SELECT * FROM XXXOEM_HR_CFDI_EMPLEADOS

SELECT * FROM XXOEM_HR_CFDI_PERCEPCIONES   

SELECT * FROM XXOEM_HR_CFDI_DEDUCCIONES

SELECT * FROM M_HR_CFDI_INCAPACIDADES

SELECT * FROM XXOEM_HR_CFDI_HORASEXTRAS

/* SCRIPT TO MAKE A BACKUP */
CREATE TABLE XXXOEM_HR_CFDI_E_BACKUP
AS SELECT * FROM XXXOEM_HR_CFDI_EMPLEADOS

CREATE TABLE XXOEM_HR_CFDI_P_BACKUP
AS SELECT * FROM XXOEM_HR_CFDI_PERCEPCIONES

CREATE TABLE XXOEM_HR_CFDI_D_BACKUP
AS SELECT * FROM XXOEM_HR_CFDI_DEDUCCIONES

CREATE TABLE M_HR_CFDI_INC_BACKUP
AS SELECT * FROM M_HR_CFDI_INCAPACIDADES   

CREATE TABLE XXOEM_HR_CFDI_HOR_BACKUP
AS SELECT * FROM XXOEM_HR_CFDI_HORASEXTRAS

/* BACKUPS MADE ON JANUARY 22 AT 1:20 PM */
SELECT * FROM XXXOEM_HR_CFDI_E_BACKUP

SELECT * FROM XXOEM_HR_CFDI_P_BACKUP

SELECT * FROM XXOEM_HR_CFDI_D_BACKUP

SELECT * FROM M_HR_CFDI_INC_BACKUP

SELECT * FROM XXOEM_HR_CFDI_HOR_BACKUP