CREATE OR REPLACE PACKAGE APPS.XXOEM_RECIBOS_ELECTRONICOS_PKG AS
/*******************************************

--  Package specifications for developed programs 
--  used by XBOL_PAY_INCIDENCIAS Form 
--
--  Type          Date          User
--  Creation      20/05/2012    Juan Manuel Lopez.                                   
--                              ERPSOL.                                                 

*******************************************/  
l_msg_reg           varchar2(1000);
l_msg_err           varchar2(1000);
l_validate          Boolean   := False;

l_recibo_id         number;
l_recibo_id1        number;
l_recibo_id2        number;
l_recibo_id3        number;
l_total_recibos     number;
l_recibo_num        varchar2(10);
l_recibo_consec     number;
l_recibo_indice     number;
l_indice_per        number;
l_total_per         number;
l_indice_ded        number;
l_total_ded         number;
l_indice_sdo        number;
l_total_sdo         number;
l_indice_inc        number;
l_total_inc         number;

  Procedure completa_saldos (p_recibo_id number,p_indice_sdo number);


  Procedure completa_percepciones (p_recibo_id number,p_indice number);


  Procedure completa_deducciones (p_recibo_id number,p_indice number);


   procedure genera_recibos_electronicos(P_PAYROLL_ACTION_ID  Number,
                            P_ELEMENT_SET_ID     Number,
                            P_DIVISION           Varchar2,
                            P_CENTRO_COSTOS      Varchar2,
                            P_DEPARTAMENTO       Varchar2,
                            P_PERSON_ID          Number,
                            P_EMP_NUM_INI        Varchar2,
                            P_EMP_NUM_FIN        Varchar2,
                            P_LOCATION_CODE      Varchar2,
                            P_RECIBO_INI          Number
                           );
                           
-- PROCEDURE CREA_RECIBO_NOMINA(P_PAYROLL_ACTION_ID  Number,
--                                P_ELEMENT_SET_ID     Number,
--                                P_DIVISION           Varchar2,
--                                P_CENTRO_COSTOS      Varchar2,
--                                P_DEPARTAMENTO       Varchar2,
--                                P_PERSON_ID          Number,
--                                P_EMP_NUM_INI        Varchar2,
--                                P_EMP_NUM_FIN        Varchar2,
--                                P_LOCATION_CODE      Varchar2,
--                                P_RECIBO_INI          Number
--                                );
FUNCTION P_DEFINED_BALANCE_ID(ass_action_id IN number) RETURN number;
                                 
END XXOEM_RECIBOS_ELECTRONICOS_PKG;
/
