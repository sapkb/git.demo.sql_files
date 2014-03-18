SELECT di  AND  PAA.PAYROLL_ACTION_ID    in  (   SELECT distinct PPA2.PAYROLL_ACTION_ID  
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