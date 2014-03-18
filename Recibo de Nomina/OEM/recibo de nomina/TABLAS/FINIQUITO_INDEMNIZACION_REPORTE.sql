SELECT PAYROLL_ID
     , PERSON_ID
     , CONCEPTO
     , ORDEN
     , TIPO
     , PERCEPCIONES
     , DEDUCCIONES
     , PERCEPCIONES - DEDUCCIONES IMPORTE 
     , TIEMPO
     , SOFT_CODING_KEYFLEX_ID
FROM (
         -- PERCEPCIONES 
         SELECT PAYROLL_ID
              , PERSON_ID
              , SOFT_CODING_KEYFLEX_ID
              , CONCEPTO
              , 1                Orden
              , Tipo
              , NVL(DIAS   , 0)  Tiempo
              , NVL(IMPORTE, 0)  Percepciones
              , 0                Deducciones
              , 0                Provisiones
         FROM
         (
         
          SELECT PAY.PAYROLL_ID 
               , PPE.PERSON_ID
               , PAS.SOFT_CODING_KEYFLEX_ID
               ,PAS.ASSIGNMENT_ID
               , UPPER(PETL.REPORTING_NAME)            Concepto
               , SUM(TO_NUMBER(PRV.RESULT_VALUE))      Importe
               , SUM((SELECT TO_NUMBER(PRRD.RESULT_VALUE)
                      FROM   PAY_RUN_RESULT_VALUES  PRRD
                         ,   PAY_INPUT_VALUES_F     PIVD    
                      WHERE  PRRD.RUN_RESULT_ID  = PRR.RUN_RESULT_ID
                      AND    PRRD.INPUT_VALUE_ID = PIVD.INPUT_VALUE_ID
                      AND    PIVD.NAME          IN ('Days', 'Hours', 'Dias Trabajados')
                    ))  Dias
               , decode (UPPER(PETL.REPORTING_NAME),
                       '2060 PRIMA DE ANTIGUEDAD FINIQUITO','F', 
                       decode (PEST.ELEMENT_SET_NAME,'FINIQUITO','F', 'INDEMNIZACION','I')
                 )    Tipo
          FROM   PAY_RUN_RESULTS              PRR
             ,   PAY_RUN_RESULT_VALUES        PRV
             ,   PAY_ELEMENT_TYPES_F          PET
             ,   PAY_ELEMENT_TYPES_F_TL       PETL
             ,   PAY_ASSIGNMENT_ACTIONS       PAA
             ,   PAY_PAYROLL_ACTIONS          PPA
             ,   PER_TIME_PERIODS             PTP
             ,   PER_ALL_ASSIGNMENTS_F        PAS
             ,   PER_ALL_PEOPLE_F             PPE 
             ,   PAY_ALL_PAYROLLS_F           PAY
             ,   PAY_ELEMENT_CLASSIFICATIONS  PEC
             ,   PAY_INPUT_VALUES_F           PIV
             ,   PAY_ELEMENT_CLASSIFICATIONS_TL  PECT 
             ,   PAY_ELEMENT_SETS_TL          PEST
          WHERE 1                          = 1
            AND PRR.RUN_RESULT_ID          = PRV.RUN_RESULT_ID
            AND PRR.ELEMENT_TYPE_ID        = PET.ELEMENT_TYPE_ID
            AND PET.ELEMENT_TYPE_ID        = PETL.ELEMENT_TYPE_ID
            AND PETL.LANGUAGE              = 'ESA'
            AND PRR.ASSIGNMENT_ACTION_ID   = PAA.ASSIGNMENT_ACTION_ID
            AND PPA.PAYROLL_ACTION_ID      = PAA.PAYROLL_ACTION_ID    
            AND PRV.INPUT_VALUE_ID         = PIV.INPUT_VALUE_ID
            AND PIV.NAME                  IN ('Pay Value')     
            AND PET.CLASSIFICATION_ID      = PEC.CLASSIFICATION_ID
            AND PECT.CLASSIFICATION_ID     = PEC.CLASSIFICATION_ID
            AND PECT.LANGUAGE              = 'ESA'
            AND    pet.element_name       not        like           ('P%VALES DE DESPENSA%')
            AND PECT.CLASSIFICATION_NAME NOT IN ('Información','Clasificación','Impuestos de Empleador','Obligaciones de Empleador')
            ---
     AND  PEST.ELEMENT_SET_ID    = PPA.ELEMENT_SET_ID
--     AND  PEST.ELEMENT_SET_NAME IN ('FINIQUITO', 'INDEMNIZACION')
     AND  PEST.LANGUAGE          = 'ESA'            
            ---
            AND PAA.ASSIGNMENT_ID          = PAS.ASSIGNMENT_ID  
            AND PPA.TIME_PERIOD_ID         = PTP.TIME_PERIOD_ID 
            AND PPA.PAYROLL_ID             = PAY.PAYROLL_ID
            AND PAS.PERSON_ID              = PPE.PERSON_ID 
            AND (PTP.REGULAR_PAYMENT_DATE >= PET.EFFECTIVE_START_DATE AND PTP.REGULAR_PAYMENT_DATE <= PET.EFFECTIVE_END_DATE) 
            AND (PTP.REGULAR_PAYMENT_DATE >= PAS.EFFECTIVE_START_DATE AND PTP.REGULAR_PAYMENT_DATE <= PAS.EFFECTIVE_END_DATE) 
            AND (PTP.REGULAR_PAYMENT_DATE >= PPE.EFFECTIVE_START_DATE AND PTP.REGULAR_PAYMENT_DATE <= PPE.EFFECTIVE_END_DATE) 
            AND (PTP.REGULAR_PAYMENT_DATE >= PAY.EFFECTIVE_START_DATE AND PTP.REGULAR_PAYMENT_DATE <= PAY.EFFECTIVE_END_DATE)
            AND (PET.ELEMENT_TYPE_ID      IN ( SELECT PER.ELEMENT_TYPE_ID 
                                               FROM   PAY_ELEMENT_SETS_TL     PES
                                                  ,   PAY_ELEMENT_TYPE_RULES  PER
                                               WHERE  PES.ELEMENT_SET_ID      = PER.ELEMENT_SET_ID    
                                                 AND  PES.LANGUAGE            = 'ESA'
                                                 AND  PES.ELEMENT_SET_NAME   IN ('PERCEPCIONES')
                                                 AND  PER.INCLUDE_OR_EXCLUDE  = 'I' )    
                OR (PET.CLASSIFICATION_ID IN ( SELECT PER.CLASSIFICATION_ID
                                               FROM   PAY_ELEMENT_SETS_TL           PES
                                                  ,   PAY_ELE_CLASSIFICATION_RULES  PER
                                               WHERE  PES.ELEMENT_SET_ID    = PER.ELEMENT_SET_ID    
                                                 AND  PES.LANGUAGE          = 'ESA'
                                                 AND  PES.ELEMENT_SET_NAME IN ('PERCEPCIONES') ) 
                    AND PET.ELEMENT_TYPE_ID NOT IN ( SELECT PER.ELEMENT_TYPE_ID 
                                                     FROM   PAY_ELEMENT_SETS_TL     PES
                                                        ,   PAY_ELEMENT_TYPE_RULES  PER
                                                     WHERE  PES.ELEMENT_SET_ID      = PER.ELEMENT_SET_ID    
                                                       AND  PES.LANGUAGE            = 'ESA'
                                                       AND  PES.ELEMENT_SET_NAME   IN ('PERCEPCIONES')
                                                       AND  PER.INCLUDE_OR_EXCLUDE  = 'E' )))  
           AND  PAA.PAYROLL_ACTION_ID    in  (   SELECT distinct PPA2.PAYROLL_ACTION_ID  
                                                   FROM   PAY_PAYROLL_ACTIONS     PPA2
                                                         ,PAY_ELEMENT_SETS_TL     PEST2
                                                         ,PAY_ASSIGNMENT_ACTIONS  PAA2
                                                   WHERE  1=1
                                                     AND  PEST2.ELEMENT_SET_ID    = PPA2.ELEMENT_SET_ID
                                                     AND  PEST2.ELEMENT_SET_NAME IN ('FINIQUITO', 'INDEMNIZACION')
                                                     AND  PEST2.LANGUAGE          = 'ESA'
                                                     AND  PAA2.PAYROLL_ACTION_ID  =  PPA2.PAYROLL_ACTION_ID
                                                     AND  PAA2.assignment_id = PAS.ASSIGNMENT_ID    
                                           )
            AND PPE.PERSON_ID         = :person_id_p  
          GROUP BY decode (PEST.ELEMENT_SET_NAME,'FINIQUITO','F', 'INDEMNIZACION','I') 
                 , PAY.PAYROLL_ID 
                 , PPE.PERSON_ID
                 , PAS.SOFT_CODING_KEYFLEX_ID
                 , UPPER(PETL.REPORTING_NAME)
                 ,PAS.ASSIGNMENT_ID
         
         
         )       
         
         WHERE IMPORTE <> 0      
         UNION ALL
         -- DEDUCCIONES 
         SELECT PAY.PAYROLL_ID 
              , PPE.PERSON_ID
              , PAS.SOFT_CODING_KEYFLEX_ID
              , DECODE(UPPER(PETL.REPORTING_NAME), 'CÁLCULO DE CUOTA DE SEGURIDAD SOCIAL EE','3100 DESCUENTO CUOTA OBRERA IMSS', 
                                                                                            'CÁLCULO DE CUOTA DE SEGURO SOCIAL EE'   ,'3100 DESCUENTO CUOTA OBRERA IMSS' , UPPER(PETL.REPORTING_NAME)) Concepto
              , 2                                                                           Orden
              , 'D'                                                                         Tipo
              , SUM(( SELECT TO_NUMBER(PRRD.RESULT_VALUE)
                       FROM  PAY_RUN_RESULT_VALUES  PRRD
                          ,  PAY_INPUT_VALUES_F     PIVD
                       WHERE PRRD.RUN_RESULT_ID   = PRR.RUN_RESULT_ID
                         AND PRRD.INPUT_VALUE_ID  = PIVD.INPUT_VALUE_ID
                         AND PIVD.NAME           IN ('Days', 'Hours', 'Dias Trabajados')))  Dias
              , 0                                                                           Percepciones
              , SUM(TO_NUMBER(PRV.RESULT_VALUE))                                            Deducciones
              , 0                                                                           Provisiones
         FROM   PAY_RUN_RESULTS              PRR
            ,   PAY_RUN_RESULT_VALUES        PRV
            ,   PAY_ELEMENT_TYPES_F          PET
            ,   PAY_ELEMENT_TYPES_F_TL       PETL
            ,   PAY_ASSIGNMENT_ACTIONS       PAA
            ,   PAY_PAYROLL_ACTIONS          PPA
            ,   PER_TIME_PERIODS             PTP
            ,   PER_ALL_ASSIGNMENTS_F        PAS    
            ,   PER_ALL_PEOPLE_F             PPE 
            ,   PAY_ALL_PAYROLLS_F           PAY
            ,   PAY_ELEMENT_CLASSIFICATIONS  PEC
            ,   PAY_INPUT_VALUES_F           PIV
            ,   PAY_ELEMENT_CLASSIFICATIONS_TL  PECT 
         WHERE  1                          = 1
           AND  PRR.RUN_RESULT_ID          = PRV.RUN_RESULT_ID
           AND  PRR.ELEMENT_TYPE_ID        = PET.ELEMENT_TYPE_ID
           AND  PET.ELEMENT_TYPE_ID        = PETL.ELEMENT_TYPE_ID
           AND  PETL.LANGUAGE              = 'ESA'
           AND  PRR.ASSIGNMENT_ACTION_ID   = PAA.ASSIGNMENT_ACTION_ID
           AND  PPA.PAYROLL_ACTION_ID      = PAA.PAYROLL_ACTION_ID    
           AND  PRV.INPUT_VALUE_ID         = PIV.INPUT_VALUE_ID
           AND  PRV.RESULT_VALUE          <> '0'
           AND  PIV.NAME                  IN ('Pay Value')
           AND  PET.CLASSIFICATION_ID      = PEC.CLASSIFICATION_ID   
           AND  PECT.CLASSIFICATION_ID     = PEC.CLASSIFICATION_ID
           AND  PECT.LANGUAGE              = 'ESA'
           AND  PECT.CLASSIFICATION_NAME NOT IN ('Información','Clasificación','Impuestos de Empleador','Obligaciones de Empleador')
           AND  PAA.ASSIGNMENT_ID          = PAS.ASSIGNMENT_ID  
           AND  PPA.TIME_PERIOD_ID         = PTP.TIME_PERIOD_ID 
           AND  PPA.PAYROLL_ID             = PAY.PAYROLL_ID
           AND  PAS.PERSON_ID              = PPE.PERSON_ID 
           AND  (PTP.REGULAR_PAYMENT_DATE >= PET.EFFECTIVE_START_DATE AND PTP.REGULAR_PAYMENT_DATE <= PET.EFFECTIVE_END_DATE) 
           AND  (PTP.REGULAR_PAYMENT_DATE >= PAS.EFFECTIVE_START_DATE AND PTP.REGULAR_PAYMENT_DATE <= PAS.EFFECTIVE_END_DATE) 
           AND  (PTP.REGULAR_PAYMENT_DATE >= PPE.EFFECTIVE_START_DATE AND PTP.REGULAR_PAYMENT_DATE <= PPE.EFFECTIVE_END_DATE) 
           AND  (PTP.REGULAR_PAYMENT_DATE >= PAY.EFFECTIVE_START_DATE AND PTP.REGULAR_PAYMENT_DATE <= PAY.EFFECTIVE_END_DATE)
           AND  (PET.ELEMENT_TYPE_ID      IN ( SELECT PER.ELEMENT_TYPE_ID 
                                               FROM   PAY_ELEMENT_SETS_TL              PES
                                                  ,   PAY_ELEMENT_TYPE_RULES           PER
                                               WHERE  PES.ELEMENT_SET_ID     = PER.ELEMENT_SET_ID    
                                                 AND  PES.LANGUAGE           = 'ESA'
                                                 AND  PES.ELEMENT_SET_NAME  IN ('DEDUCCIONES' )
                                                 AND  PER.INCLUDE_OR_EXCLUDE = 'I' )    
                OR (PET.CLASSIFICATION_ID IN ( SELECT PER.CLASSIFICATION_ID
                                               FROM   PAY_ELEMENT_SETS_TL           PES
                                                  ,   PAY_ELE_CLASSIFICATION_RULES  PER
                                               WHERE  PES.ELEMENT_SET_ID    = PER.ELEMENT_SET_ID    
                                                 AND  PES.LANGUAGE          = 'ESA'
                                                 AND  PES.ELEMENT_SET_NAME IN ('DEDUCCIONES')) 
                    AND PET.ELEMENT_TYPE_ID NOT IN ( SELECT PER.ELEMENT_TYPE_ID 
                                                     FROM   PAY_ELEMENT_SETS_TL     PES
                                                        ,   PAY_ELEMENT_TYPE_RULES  PER
                                                     WHERE  PES.ELEMENT_SET_ID      = PER.ELEMENT_SET_ID    
                                                       AND  PES.LANGUAGE            = 'ESA'
                                                       AND  PES.ELEMENT_SET_NAME   IN ('DEDUCCIONES')
                                                       AND  PER.INCLUDE_OR_EXCLUDE  = 'E' )))  
           AND  PAA.PAYROLL_ACTION_ID    in  (   SELECT distinct PPA2.PAYROLL_ACTION_ID  
                                                   FROM   PAY_PAYROLL_ACTIONS     PPA2
                                                         ,PAY_ELEMENT_SETS_TL     PEST2
                                                         ,PAY_ASSIGNMENT_ACTIONS  PAA2
                                                   WHERE  1=1
                                                     AND  PEST2.ELEMENT_SET_ID    = PPA2.ELEMENT_SET_ID
                                                     AND  PEST2.ELEMENT_SET_NAME IN ('FINIQUITO', 'INDEMNIZACION')
                                                     AND  PEST2.LANGUAGE          = 'ESA'
                                                     AND  PAA2.PAYROLL_ACTION_ID  =  PPA2.PAYROLL_ACTION_ID
                                                     AND  PAA2.assignment_id = PAS.ASSIGNMENT_ID
                                               )
            AND PPE.PERSON_ID         = :person_id_p  
         GROUP BY PAY.PAYROLL_ID 
                , PPE.PERSON_ID
                , PAS.SOFT_CODING_KEYFLEX_ID
                , UPPER(PETL.REPORTING_NAME)  
         UNION ALL
         -- PERCEPCIONES NEGATIVAS 
         SELECT PAY.PAYROLL_ID 
              , PPE.PERSON_ID
              , PAS.SOFT_CODING_KEYFLEX_ID
              , UPPER(PETL.REPORTING_NAME)                                                 Concepto
              , 2                                                                          Orden
              , 'N'                                                                        Tipo
              , SUM(( SELECT TO_NUMBER(PRRD.RESULT_VALUE)
                      FROM   PAY_RUN_RESULT_VALUES  PRRD
                         ,   PAY_INPUT_VALUES_F     PIVD    
                      WHERE  PRRD.RUN_RESULT_ID  = PRR.RUN_RESULT_ID
                        AND  PRRD.INPUT_VALUE_ID = PIVD.INPUT_VALUE_ID
                        AND  PIVD.NAME          IN ('Days', 'Hours', 'Dias Trabajados')))  Dias
              , 0                                                                          Percepciones
              , SUM(TO_NUMBER(PRV.RESULT_VALUE * -1))                                      Deducciones
              , 0                                                                          Provisones
         FROM   PAY_RUN_RESULTS              PRR
            ,   PAY_RUN_RESULT_VALUES        PRV
            ,   PAY_ELEMENT_TYPES_F          PET
            ,   PAY_ELEMENT_TYPES_F_TL       PETL
            ,   PAY_ASSIGNMENT_ACTIONS       PAA
            ,   PAY_PAYROLL_ACTIONS          PPA
            ,   PER_TIME_PERIODS             PTP
            ,   PER_ALL_ASSIGNMENTS_F        PAS    
            ,   PER_ALL_PEOPLE_F             PPE
            ,   PAY_ALL_PAYROLLS_F           PAY
            ,   PAY_ELEMENT_CLASSIFICATIONS  PEC
            ,   PAY_INPUT_VALUES_F           PIV
            ,   PAY_ELEMENT_CLASSIFICATIONS_TL  PECT 
         WHERE  1                          = 1
           AND  PRR.RUN_RESULT_ID          = PRV.RUN_RESULT_ID
           AND  PRR.ELEMENT_TYPE_ID        = PET.ELEMENT_TYPE_ID
           AND  PET.ELEMENT_TYPE_ID        = PETL.ELEMENT_TYPE_ID
           AND  PETL.LANGUAGE              = 'ESA'
           AND  PRR.ASSIGNMENT_ACTION_ID   = PAA.ASSIGNMENT_ACTION_ID
           AND  PPA.PAYROLL_ACTION_ID      = PAA.PAYROLL_ACTION_ID    
           AND  PRV.INPUT_VALUE_ID         = PIV.INPUT_VALUE_ID
           AND  PIV.NAME                  IN ('Pay Value')
           AND  PRV.RESULT_VALUE          <> '0'
           AND  PET.CLASSIFICATION_ID      = PEC.CLASSIFICATION_ID   
           AND  PECT.CLASSIFICATION_ID     = PEC.CLASSIFICATION_ID
           AND  PECT.LANGUAGE              = 'ESA'
           AND  PECT.CLASSIFICATION_NAME NOT IN ('Información','Clasificación','Impuestos de Empleador','Obligaciones de Empleador')
           AND  PAA.ASSIGNMENT_ID          = PAS.ASSIGNMENT_ID  
           AND  PPA.TIME_PERIOD_ID         = PTP.TIME_PERIOD_ID 
           AND  PPA.PAYROLL_ID             = PAY.PAYROLL_ID
           AND  PAS.PERSON_ID              = PPE.PERSON_ID 
           AND  (PTP.REGULAR_PAYMENT_DATE >= PET.EFFECTIVE_START_DATE AND PTP.REGULAR_PAYMENT_DATE <= PET.EFFECTIVE_END_DATE) 
           AND  (PTP.REGULAR_PAYMENT_DATE >= PAS.EFFECTIVE_START_DATE AND PTP.REGULAR_PAYMENT_DATE <= PAS.EFFECTIVE_END_DATE) 
           AND  (PTP.REGULAR_PAYMENT_DATE >= PPE.EFFECTIVE_START_DATE AND PTP.REGULAR_PAYMENT_DATE <= PPE.EFFECTIVE_END_DATE) 
           AND  (PTP.REGULAR_PAYMENT_DATE >= PAY.EFFECTIVE_START_DATE AND PTP.REGULAR_PAYMENT_DATE <= PAY.EFFECTIVE_END_DATE)
           AND  (PET.ELEMENT_TYPE_ID      IN ( SELECT PER.ELEMENT_TYPE_ID 
                                               FROM   PAY_ELEMENT_SETS_TL     PES
                                                  ,   PAY_ELEMENT_TYPE_RULES  PER
                                               WHERE  PES.ELEMENT_SET_ID      = PER.ELEMENT_SET_ID    
                                                 AND  PES.LANGUAGE            = 'ESA'
                                                 AND  PES.ELEMENT_SET_NAME   IN ('PERCEPCIONES NEGATIVAS')
                                                 AND  PER.INCLUDE_OR_EXCLUDE  = 'I' )    
                 OR (PET.CLASSIFICATION_ID IN ( SELECT PER.CLASSIFICATION_ID
                                                FROM   PAY_ELEMENT_SETS_TL           PES
                                                   ,   PAY_ELE_CLASSIFICATION_RULES  PER
                                                WHERE  PES.ELEMENT_SET_ID    = PER.ELEMENT_SET_ID    
                                                  AND  PES.LANGUAGE          = 'ESA'
                                                  AND  PES.ELEMENT_SET_NAME IN ('PERCEPCIONES NEGATIVAS')                            ) 
                     AND PET.ELEMENT_TYPE_ID NOT IN ( SELECT PER.ELEMENT_TYPE_ID 
                                                      FROM   PAY_ELEMENT_SETS_TL     PES
                                                         ,   PAY_ELEMENT_TYPE_RULES  PER
                                                      WHERE  PES.ELEMENT_SET_ID      = PER.ELEMENT_SET_ID    
                                                        AND  PES.LANGUAGE            = 'ESA'
                                                        AND  PES.ELEMENT_SET_NAME   IN ('PERCEPCIONES NEGATIVAS')
                                                        AND  PER.INCLUDE_OR_EXCLUDE  = 'E' )))  
           AND  PAA.PAYROLL_ACTION_ID    in  (   SELECT distinct PPA2.PAYROLL_ACTION_ID  
                                                   FROM   PAY_PAYROLL_ACTIONS     PPA2
                                                         ,PAY_ELEMENT_SETS_TL     PEST2
                                                         ,PAY_ASSIGNMENT_ACTIONS  PAA2
                                                   WHERE  1=1
                                                     AND  PEST2.ELEMENT_SET_ID    = PPA2.ELEMENT_SET_ID
                                                     AND  PEST2.ELEMENT_SET_NAME IN ('FINIQUITO', 'INDEMNIZACION')
                                                     AND  PEST2.LANGUAGE          = 'ESA'
                                                     AND  PAA2.PAYROLL_ACTION_ID  =  PPA2.PAYROLL_ACTION_ID
                                                     AND  PAA2.assignment_id = PAS.ASSIGNMENT_ID
                                               )
            AND PPE.PERSON_ID         = :person_id_p  
         GROUP BY PAY.PAYROLL_ID 
                , PTP.TIME_PERIOD_ID 
                , PPE.PERSON_ID
                , PAS.SOFT_CODING_KEYFLEX_ID
                , NVL(TO_NUMBER(PET.ATTRIBUTE1), 1000) 
                , UPPER(PETL.REPORTING_NAME)  
                , PTP.REGULAR_PAYMENT_DATE
                , PET.ELEMENT_TYPE_ID order by CONCEPTO)