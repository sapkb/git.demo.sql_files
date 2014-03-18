CREATE OR REPLACE PACKAGE APPS.XXOEM_RECIBOS_ELECTRONICOS_PKG
AS
   /*******************************************

   --  Package specifications for developed programs
   --  used by XBOL_PAY_INCIDENCIAS Form
   --
   --  Type          Date          User
   --  Creation      20/05/2012    Juan Manuel Lopez.
   --                              ERPSOL.

   *******************************************/
   l_msg_reg         VARCHAR2 (1000);
   l_msg_err         VARCHAR2 (1000);
   l_validate        BOOLEAN := FALSE;

   l_recibo_id       NUMBER;
   l_recibo_id1      NUMBER;
   l_recibo_id2      NUMBER;
   l_recibo_id3      NUMBER;
   l_total_recibos   NUMBER;
   l_recibo_num      VARCHAR2 (10);
   l_recibo_consec   NUMBER;
   l_recibo_indice   NUMBER;
   l_indice_per      NUMBER;
   l_total_per       NUMBER;
   l_indice_ded      NUMBER;
   l_total_ded       NUMBER;
   l_indice_sdo      NUMBER;
   l_total_sdo       NUMBER;
   l_indice_inc      NUMBER;
   l_total_inc       NUMBER;
   l_indice_EX       NUMBER;
   l_total_EX        NUMBER;

   PROCEDURE completa_saldos (p_recibo_id NUMBER, p_indice_sdo NUMBER);


   PROCEDURE completa_percepciones (p_recibo_id NUMBER, p_indice NUMBER);


   PROCEDURE completa_deducciones (p_recibo_id NUMBER, p_indice NUMBER);


   PROCEDURE genera_recibos_electronicos (P_ERRORMSG     OUT VARCHAR2
              ,P_ERRORCODE    OUT NUMBER ,P_PAYROLL_ACTION_ID    NUMBER,
                                        --  P_ELEMENT_SET_ID       NUMBER,
                                          P_DIVISION             VARCHAR2,
                                          P_CENTRO_COSTOS        VARCHAR2,
                                          P_DEPARTAMENTO         VARCHAR2,
                                          P_PERSON_ID            NUMBER
                                          --P_EMP_NUM_INI          VARCHAR2,
                                          --P_EMP_NUM_FIN          VARCHAR2,
                                          --P_LOCATION_CODE        VARCHAR2,
                                         -- P_RECIBO_INI           NUMBER
                                         );
   
   PROCEDURE IMP_O(P_DATA IN VARCHAR2);

PROCEDURE IMP_L(P_DATA IN VARCHAR2);

FUNCTION G_XML(P_ETIQUETA IN VARCHAR2,P_DATA IN VARCHAR2) RETURN VARCHAR2;

FUNCTION P_DEFINED_BALANCE_ID (ass_action_id IN NUMBER)
      RETURN NUMBER;
      
FUNCTION F_REGRESA_SDI (PIVID IN NUMBER, P_RRID IN NUMBER)
      RETURN NUMBER;      
      
END XXOEM_RECIBOS_ELECTRONICOS_PKG;
/
