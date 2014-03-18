--cursor c_deducciones (P_ELEMENT_SET_ID number, p_PAYROLL_ACTION_ID  number, p_person_id number, p_time_period_id number) is
select prueba.concepto,prueba.over_by,prueba.dias,prueba.gravado,prueba.exento 
FROM  
       (Select --distinct (sum(prv.result_value) over (partition by petl.reporting_name)) over_by,pay.payroll_id, 
                  ptp.time_period_id 
                  ,ppe.person_id
                  ,decode(upper(petl.reporting_name),'CÁLCULO DE CUOTA DE SEGURIDAD SOCIAL EE','3100 DESCUENTO CUOTA OBRERA IMSS',
                                                     'CÁLCULO DE CUOTA DE SEGURO SOCIAL EE'   ,'3100 DESCUENTO CUOTA OBRERA IMSS' ,upper(petl.reporting_name)) Concepto
,sum(to_number(prv.result_value))over (partition by petl.reporting_name) over_by                                                     
                  ,ptp.REGULAR_PAYMENT_DATE
                  --,to_number(prv.result_value)      importe
                  --,to_number(prv.result_value)     importe_deducciones
                  ,pet.element_type_id
                  ,(Select to_number(prrd.result_value)
                    From   pay_run_result_values  prrd
                          ,pay_input_values_f     pivd    
                    where  prrd.run_result_id  = prr.run_result_id
                    and    prrd.INPUT_VALUE_ID = pivd.INPUT_VALUE_ID
                    and    pivd.name           in  ('Days', 'Hours', 'Dias Trabajados')
                    )  dias
            ,nvl( (SELECT 
            RRV.RESULT_VALUE
            FROM   HR_LOOKUPS LO1,
            HR_LOOKUPS LO2,
            PAY_INPUT_VALUES_F INV,
            PAY_INPUT_VALUES_F_TL INVTL,
            PAY_RUN_RESULT_VALUES RRV
    WHERE       INV.INPUT_VALUE_ID = INVTL.INPUT_VALUE_ID
            AND INVTL.LANGUAGE = USERENV ('LANG')
            AND RRV.INPUT_VALUE_ID = INV.INPUT_VALUE_ID /* DECODE NON-USER ENTERABLE TO NOT MANDATORY */
            --and RRV.INPUT_VALUE_ID in(1667,1666)
            --and RRV.INPUT_VALUE_ID=1666--efe
            and invtl.name='ISR Subject'--efe
            AND LO1.LOOKUP_TYPE = 'YES_NO'
            AND LO1.LOOKUP_CODE =
              DECODE (INV.MANDATORY_FLAG, 'X', 'N', INV.MANDATORY_FLAG)
            AND LO2.LOOKUP_TYPE = 'UNITS'
            AND LO2.LOOKUP_CODE = INV.UOM
            and  (RRV.RUN_RESULT_ID = pRV.RUN_RESULT_ID--13831862
            )),0) gravado,
            nvl((SELECT 
            RRV.RESULT_VALUE
            FROM   HR_LOOKUPS LO1,
            HR_LOOKUPS LO2,
            PAY_INPUT_VALUES_F INV,
            PAY_INPUT_VALUES_F_TL INVTL,
            PAY_RUN_RESULT_VALUES RRV
    WHERE       INV.INPUT_VALUE_ID = INVTL.INPUT_VALUE_ID
            AND INVTL.LANGUAGE = USERENV ('LANG')
            AND RRV.INPUT_VALUE_ID = INV.INPUT_VALUE_ID /* DECODE NON-USER ENTERABLE TO NOT MANDATORY */
            --and RRV.INPUT_VALUE_ID in(1667,1666)
            --and RRV.INPUT_VALUE_ID=1667--efe
            and invtl.name='ISR Exempt'--efe
            AND LO1.LOOKUP_TYPE = 'YES_NO'
            AND LO1.LOOKUP_CODE =
              DECODE (INV.MANDATORY_FLAG, 'X', 'N', INV.MANDATORY_FLAG)
            AND LO2.LOOKUP_TYPE = 'UNITS'
            AND LO2.LOOKUP_CODE = INV.UOM
            and  (RRV.RUN_RESULT_ID = pRV.RUN_RESULT_ID--13831862
            )),0) exento
            from   pay_run_results                  prr
                  ,pay_run_result_values            prv
                  ,pay_element_types_f              pet
                  ,pay_element_types_f_tl           petl
                  ,pay_assignment_actions           paa
                  ,pay_payroll_actions              ppa
                  ,per_time_periods                 ptp
                  ,per_all_assignments_f            pas    
                  ,per_all_people_f                 ppe   ---ok 
                  ,pay_all_payrolls_f               pay   ---ok
                  ,pay_element_classifications      pec   ---ok
            --      ,PAY_ELEMENT_SETS_TL              pes
            --      ,PAY_ELEMENT_TYPE_RULES           per
                  ,pay_input_values_f               piv
            Where  1=1
            and    prr.RUN_RESULT_ID                 =             prv.RUN_RESULT_ID
            and    prr.ELEMENT_TYPE_ID               =             pet.ELEMENT_TYPE_ID
            and    pet.ELEMENT_TYPE_ID               =             petl.ELEMENT_TYPE_ID
            and    petl.language                     =             'ESA'
            and    prr.ASSIGNMENT_ACTION_ID          =             paa.ASSIGNMENT_ACTION_ID
            and    ppa.PAYROLL_ACTION_ID             =             paa.PAYROLL_ACTION_ID    
            and    prv.INPUT_VALUE_ID                =             piv.INPUT_VALUE_ID
            and    prv.result_value  <> '0'
            and    piv.name                           in           ('Pay Value')       ---      ('ISR Subject','ISR Exempt')
            --and    ppa.BUSINESS_GROUP_ID             =             81   
            and    pet.CLASSIFICATION_ID             =             pec.CLASSIFICATION_ID   
            and    paa.ASSIGNMENT_ID                 =             pas.ASSIGNMENT_ID  
            and    ppa.TIME_PERIOD_ID                =             ptp.TIME_PERIOD_ID 
            and    ppa.PAYROLL_ID                    =             pay.PAYROLL_ID
            and    pas.PERSON_ID                     =             ppe.PERSON_ID 
            and    (ptp.REGULAR_PAYMENT_DATE        >=             pet.EFFECTIVE_START_DATE and ptp.REGULAR_PAYMENT_DATE   <= pet.EFFECTIVE_END_DATE) 
            and    (ptp.REGULAR_PAYMENT_DATE        >=             pas.EFFECTIVE_START_DATE and ptp.REGULAR_PAYMENT_DATE   <= pas.EFFECTIVE_END_DATE) 
            and    (ptp.REGULAR_PAYMENT_DATE        >=             ppe.EFFECTIVE_START_DATE and ptp.REGULAR_PAYMENT_DATE   <= ppe.EFFECTIVE_END_DATE) 
            and    (ptp.REGULAR_PAYMENT_DATE        >=             pay.EFFECTIVE_START_DATE and ptp.REGULAR_PAYMENT_DATE   <= pay.EFFECTIVE_END_DATE)
            and  (  pet.ELEMENT_TYPE_ID              in
                   ( Select  per.ELEMENT_TYPE_ID 
                     from    PAY_ELEMENT_TYPE_RULES           per
                     where   per.ELEMENT_SET_ID                =     :P_ELEMENT_SET_ID      
                     or      :P_ELEMENT_SET_ID is null      
                    )
                  )  
            and  (
                 pet.ELEMENT_TYPE_ID             in
                   ( Select  per.ELEMENT_TYPE_ID 
                     from    PAY_ELEMENT_SETS_TL              pes
                            ,PAY_ELEMENT_TYPE_RULES           per
                     where   pes.ELEMENT_SET_ID                =             per.ELEMENT_SET_ID    
                       and   pes.language                      =             'ESA'
                       and   pes.element_set_name             in              ('DEDUCCIONES_RECIBO' )
                       and   per.include_or_exclude            =              'I'
                    )    
                 or (  pet.CLASSIFICATION_ID              in 
                           (Select  per.CLASSIFICATION_ID
                             from    PAY_ELEMENT_SETS_TL              pes
                                    ,PAY_ELE_CLASSIFICATION_RULES     per
                             where   pes.ELEMENT_SET_ID                =             per.ELEMENT_SET_ID    
                               and   pes.language                      =             'ESA'
                               and   pes.element_set_name             in              ('DEDUCCIONES_RECIBO')
                            ) 
                          and pet.ELEMENT_TYPE_ID        not      in
                           ( Select  per.ELEMENT_TYPE_ID 
                             from    PAY_ELEMENT_SETS_TL              pes
                                    ,PAY_ELEMENT_TYPE_RULES           per
                             where   pes.ELEMENT_SET_ID                =             per.ELEMENT_SET_ID    
                               and   pes.language                      =             'ESA'
                               and   pes.element_set_name             in               ('DEDUCCIONES_RECIBO')
                               and   per.include_or_exclude            =              'E'
                            ) 
                       )
                   )  
            and    paa.payroll_action_id                           = :P_PAYROLL_ACTION_ID    
            and    ppe.person_id                          = :p_PERSON_ID
            --and    ptp.time_period_id     = :p_TIME_PERIOD_ID
 Union all
            Select --pay.payroll_id,
            ptp.time_period_id 
                  ,ppe.person_id
                  ,upper(petl.reporting_name) Concepto,
 sum(to_number(prv.result_value))over (partition by petl.reporting_name) over_by
                  ,ptp.REGULAR_PAYMENT_DATE
--                  ,to_number(prv.result_value*-1)         importe
--                  ,to_number(prv.result_value*-1)     importe_deducciones
                  ,pet.element_type_id
                  ,(Select to_number(prrd.result_value)
                    From   pay_run_result_values  prrd
                          ,pay_input_values_f     pivd    
                    where  prrd.run_result_id  = prr.run_result_id
                    and    prrd.INPUT_VALUE_ID = pivd.INPUT_VALUE_ID
                    and    pivd.name           in ('Days', 'Hours', 'Dias Trabajados')
                    )  dias
                            ,nvl( (SELECT 
            RRV.RESULT_VALUE
            FROM   HR_LOOKUPS LO1,
            HR_LOOKUPS LO2,
            PAY_INPUT_VALUES_F INV,
            PAY_INPUT_VALUES_F_TL INVTL,
            PAY_RUN_RESULT_VALUES RRV
    WHERE       INV.INPUT_VALUE_ID = INVTL.INPUT_VALUE_ID
            AND INVTL.LANGUAGE = USERENV ('LANG')
            AND RRV.INPUT_VALUE_ID = INV.INPUT_VALUE_ID /* DECODE NON-USER ENTERABLE TO NOT MANDATORY */
            --and RRV.INPUT_VALUE_ID in(1667,1666)
            --and RRV.INPUT_VALUE_ID=1666--efe
            and invtl.name='ISR Subject'--efe
            AND LO1.LOOKUP_TYPE = 'YES_NO'
            AND LO1.LOOKUP_CODE =
              DECODE (INV.MANDATORY_FLAG, 'X', 'N', INV.MANDATORY_FLAG)
            AND LO2.LOOKUP_TYPE = 'UNITS'
            AND LO2.LOOKUP_CODE = INV.UOM
            and  (RRV.RUN_RESULT_ID = pRV.RUN_RESULT_ID--13831862
            )),0) gravado,
            nvl((SELECT 
            RRV.RESULT_VALUE
            FROM   HR_LOOKUPS LO1,
            HR_LOOKUPS LO2,
            PAY_INPUT_VALUES_F INV,
            PAY_INPUT_VALUES_F_TL INVTL,
            PAY_RUN_RESULT_VALUES RRV
    WHERE       INV.INPUT_VALUE_ID = INVTL.INPUT_VALUE_ID
            AND INVTL.LANGUAGE = USERENV ('LANG')
            AND RRV.INPUT_VALUE_ID = INV.INPUT_VALUE_ID /* DECODE NON-USER ENTERABLE TO NOT MANDATORY */
            --and RRV.INPUT_VALUE_ID in(1667,1666)
            --and RRV.INPUT_VALUE_ID=1667--efe
            and invtl.name='ISR Exempt'--efe
            AND LO1.LOOKUP_TYPE = 'YES_NO'
            AND LO1.LOOKUP_CODE =
              DECODE (INV.MANDATORY_FLAG, 'X', 'N', INV.MANDATORY_FLAG)
            AND LO2.LOOKUP_TYPE = 'UNITS'
            AND LO2.LOOKUP_CODE = INV.UOM
            and  (RRV.RUN_RESULT_ID = pRV.RUN_RESULT_ID--13831862
            )),0) exento
            from   pay_run_results                  prr
                  ,pay_run_result_values            prv
                  ,pay_element_types_f              pet
                  ,pay_element_types_f_tl           petl
                  ,pay_assignment_actions           paa
                  ,pay_payroll_actions              ppa
                  ,per_time_periods                 ptp
                  ,per_all_assignments_f            pas    
                  ,per_all_people_f                 ppe   ---ok 
                  ,pay_all_payrolls_f               pay   ---ok
                  ,pay_element_classifications      pec   ---ok
            --      ,PAY_ELEMENT_SETS_TL              pes
            --      ,PAY_ELEMENT_TYPE_RULES           per
                  ,pay_input_values_f               piv
            Where  1=1
            and    prr.RUN_RESULT_ID                 =             prv.RUN_RESULT_ID
            and    prr.ELEMENT_TYPE_ID               =             pet.ELEMENT_TYPE_ID
            and    pet.ELEMENT_TYPE_ID               =             petl.ELEMENT_TYPE_ID
            and    petl.language                     =             'ESA'
            and    prr.ASSIGNMENT_ACTION_ID          =             paa.ASSIGNMENT_ACTION_ID
            and    ppa.PAYROLL_ACTION_ID             =             paa.PAYROLL_ACTION_ID    
            and    prv.INPUT_VALUE_ID                =             piv.INPUT_VALUE_ID
            and    piv.name                           in           ('Pay Value')       ---      ('ISR Subject','ISR Exempt')
            and    prv.result_value  <> '0'
            --and    ppa.BUSINESS_GROUP_ID             =             81   
            and    pet.CLASSIFICATION_ID             =             pec.CLASSIFICATION_ID   
            and    paa.ASSIGNMENT_ID                 =             pas.ASSIGNMENT_ID  
            and    ppa.TIME_PERIOD_ID                =             ptp.TIME_PERIOD_ID 
            and    ppa.PAYROLL_ID                    =             pay.PAYROLL_ID
            and    pas.PERSON_ID                     =             ppe.PERSON_ID 
            and    (ptp.REGULAR_PAYMENT_DATE        >=             pet.EFFECTIVE_START_DATE and ptp.REGULAR_PAYMENT_DATE   <= pet.EFFECTIVE_END_DATE) 
            and    (ptp.REGULAR_PAYMENT_DATE        >=             pas.EFFECTIVE_START_DATE and ptp.REGULAR_PAYMENT_DATE   <= pas.EFFECTIVE_END_DATE) 
            and    (ptp.REGULAR_PAYMENT_DATE        >=             ppe.EFFECTIVE_START_DATE and ptp.REGULAR_PAYMENT_DATE   <= ppe.EFFECTIVE_END_DATE) 
            and    (ptp.REGULAR_PAYMENT_DATE        >=             pay.EFFECTIVE_START_DATE and ptp.REGULAR_PAYMENT_DATE   <= pay.EFFECTIVE_END_DATE)
            and  (  pet.ELEMENT_TYPE_ID              in
                   ( Select  per.ELEMENT_TYPE_ID 
                     from    PAY_ELEMENT_TYPE_RULES           per
                     where   per.ELEMENT_SET_ID                =     :P_ELEMENT_SET_ID      
                     or      :P_ELEMENT_SET_ID is null      
                    )
                  )  
            and  (
                 pet.ELEMENT_TYPE_ID             in
                   ( Select  per.ELEMENT_TYPE_ID 
                     from    PAY_ELEMENT_SETS_TL              pes
                            ,PAY_ELEMENT_TYPE_RULES           per
                     where   pes.ELEMENT_SET_ID                =             per.ELEMENT_SET_ID    
                       and   pes.language                      =             'ESA'
                       and   pes.element_set_name             in              ('PERCEPCIONES NEGATIVAS_RECIBO' )
                       and   per.include_or_exclude            =              'I'
                    )    
                 or (  pet.CLASSIFICATION_ID              in 
                           (Select  per.CLASSIFICATION_ID
                             from    PAY_ELEMENT_SETS_TL              pes
                                    ,PAY_ELE_CLASSIFICATION_RULES     per
                             where   pes.ELEMENT_SET_ID                =             per.ELEMENT_SET_ID    
                               and   pes.language                      =             'ESA'
                               and   pes.element_set_name             in              ('PERCEPCIONES NEGATIVAS_RECIBO')
                            ) 
                          and pet.ELEMENT_TYPE_ID        not      in
                           ( Select  per.ELEMENT_TYPE_ID 
                             from    PAY_ELEMENT_SETS_TL              pes
                                    ,PAY_ELEMENT_TYPE_RULES           per
                             where   pes.ELEMENT_SET_ID                =             per.ELEMENT_SET_ID    
                               and   pes.language                      =             'ESA'
                               and   pes.element_set_name             in               ('PERCEPCIONES NEGATIVAS_RECIBO')
                               and   per.include_or_exclude            =              'E'
                            ) 
                       )
                   )  
            and    paa.payroll_action_id                           = :P_PAYROLL_ACTION_ID    
            and    ppe.person_id                          = :p_PERSON_ID
            --and    ptp.time_period_id     = :p_TIME_PERIOD_ID
) prueba
group by prueba.concepto,prueba.over_by,prueba.dias,prueba.gravado,prueba.exento
 
-------------------------------
-------------------------------
--------------------------------

Select --distinct (sum(prv.result_value) over (partition by petl.reporting_name)) over_by,pay.payroll_id, 
                  ptp.time_period_id 
                  ,ppe.person_id
                  ,decode(upper(petl.reporting_name),'CÁLCULO DE CUOTA DE SEGURIDAD SOCIAL EE','3100 DESCUENTO CUOTA OBRERA IMSS',
                                                     'CÁLCULO DE CUOTA DE SEGURO SOCIAL EE'   ,'3100 DESCUENTO CUOTA OBRERA IMSS' ,upper(petl.reporting_name)) Concepto
,sum(to_number(prv.result_value))over (partition by petl.reporting_name) over_by                                                     
                  ,ptp.REGULAR_PAYMENT_DATE
                  --,to_number(prv.result_value)      importe
                  --,to_number(prv.result_value)     importe_deducciones
                  ,pet.element_type_id
                  ,(Select to_number(prrd.result_value)
                    From   pay_run_result_values  prrd
                          ,pay_input_values_f     pivd    
                    where  prrd.run_result_id  = prr.run_result_id
                    and    prrd.INPUT_VALUE_ID = pivd.INPUT_VALUE_ID
                    and    pivd.name           in  ('Days', 'Hours', 'Dias Trabajados')
                    )  dias
            ,nvl( (SELECT 
            RRV.RESULT_VALUE
            FROM   HR_LOOKUPS LO1,
            HR_LOOKUPS LO2,
            PAY_INPUT_VALUES_F INV,
            PAY_INPUT_VALUES_F_TL INVTL,
            PAY_RUN_RESULT_VALUES RRV
    WHERE       INV.INPUT_VALUE_ID = INVTL.INPUT_VALUE_ID
            AND INVTL.LANGUAGE = USERENV ('LANG')
            AND RRV.INPUT_VALUE_ID = INV.INPUT_VALUE_ID /* DECODE NON-USER ENTERABLE TO NOT MANDATORY */
            --and RRV.INPUT_VALUE_ID in(1667,1666)
            --and RRV.INPUT_VALUE_ID=1666--efe
            and invtl.name='ISR Subject'--efe
            AND LO1.LOOKUP_TYPE = 'YES_NO'
            AND LO1.LOOKUP_CODE =
              DECODE (INV.MANDATORY_FLAG, 'X', 'N', INV.MANDATORY_FLAG)
            AND LO2.LOOKUP_TYPE = 'UNITS'
            AND LO2.LOOKUP_CODE = INV.UOM
            and  (RRV.RUN_RESULT_ID = pRV.RUN_RESULT_ID--13831862
            )),0) gravado,
            nvl((SELECT 
            RRV.RESULT_VALUE
            FROM   HR_LOOKUPS LO1,
            HR_LOOKUPS LO2,
            PAY_INPUT_VALUES_F INV,
            PAY_INPUT_VALUES_F_TL INVTL,
            PAY_RUN_RESULT_VALUES RRV
    WHERE       INV.INPUT_VALUE_ID = INVTL.INPUT_VALUE_ID
            AND INVTL.LANGUAGE = USERENV ('LANG')
            AND RRV.INPUT_VALUE_ID = INV.INPUT_VALUE_ID /* DECODE NON-USER ENTERABLE TO NOT MANDATORY */
            --and RRV.INPUT_VALUE_ID in(1667,1666)
            --and RRV.INPUT_VALUE_ID=1667--efe
            and invtl.name='ISR Exempt'--efe
            AND LO1.LOOKUP_TYPE = 'YES_NO'
            AND LO1.LOOKUP_CODE =
              DECODE (INV.MANDATORY_FLAG, 'X', 'N', INV.MANDATORY_FLAG)
            AND LO2.LOOKUP_TYPE = 'UNITS'
            AND LO2.LOOKUP_CODE = INV.UOM
            and  (RRV.RUN_RESULT_ID = pRV.RUN_RESULT_ID--13831862
            )),0) exento
            from   pay_run_results                  prr
                  ,pay_run_result_values            prv
                  ,pay_element_types_f              pet
                  ,pay_element_types_f_tl           petl
                  ,pay_assignment_actions           paa
                  ,pay_payroll_actions              ppa
                  ,per_time_periods                 ptp
                  ,per_all_assignments_f            pas    
                  ,per_all_people_f                 ppe   ---ok 
                  ,pay_all_payrolls_f               pay   ---ok
                  ,pay_element_classifications      pec   ---ok
            --      ,PAY_ELEMENT_SETS_TL              pes
            --      ,PAY_ELEMENT_TYPE_RULES           per
                  ,pay_input_values_f               piv
            Where  1=1
            and    prr.RUN_RESULT_ID                 =             prv.RUN_RESULT_ID
            and    prr.ELEMENT_TYPE_ID               =             pet.ELEMENT_TYPE_ID
            and    pet.ELEMENT_TYPE_ID               =             petl.ELEMENT_TYPE_ID
            and    petl.language                     =             'ESA'
            and    prr.ASSIGNMENT_ACTION_ID          =             paa.ASSIGNMENT_ACTION_ID
            and    ppa.PAYROLL_ACTION_ID             =             paa.PAYROLL_ACTION_ID    
            and    prv.INPUT_VALUE_ID                =             piv.INPUT_VALUE_ID
            and    prv.result_value  <> '0'
            and    piv.name                           in           ('Pay Value')       ---      ('ISR Subject','ISR Exempt')
            --and    ppa.BUSINESS_GROUP_ID             =             81   
            and    pet.CLASSIFICATION_ID             =             pec.CLASSIFICATION_ID   
            and    paa.ASSIGNMENT_ID                 =             pas.ASSIGNMENT_ID  
            and    ppa.TIME_PERIOD_ID                =             ptp.TIME_PERIOD_ID 
            and    ppa.PAYROLL_ID                    =             pay.PAYROLL_ID
            and    pas.PERSON_ID                     =             ppe.PERSON_ID 
            and    (ptp.REGULAR_PAYMENT_DATE        >=             pet.EFFECTIVE_START_DATE and ptp.REGULAR_PAYMENT_DATE   <= pet.EFFECTIVE_END_DATE) 
            and    (ptp.REGULAR_PAYMENT_DATE        >=             pas.EFFECTIVE_START_DATE and ptp.REGULAR_PAYMENT_DATE   <= pas.EFFECTIVE_END_DATE) 
            and    (ptp.REGULAR_PAYMENT_DATE        >=             ppe.EFFECTIVE_START_DATE and ptp.REGULAR_PAYMENT_DATE   <= ppe.EFFECTIVE_END_DATE) 
            and    (ptp.REGULAR_PAYMENT_DATE        >=             pay.EFFECTIVE_START_DATE and ptp.REGULAR_PAYMENT_DATE   <= pay.EFFECTIVE_END_DATE)
            and  (  pet.ELEMENT_TYPE_ID              in
                   ( Select  per.ELEMENT_TYPE_ID 
                     from    PAY_ELEMENT_TYPE_RULES           per
                     where   per.ELEMENT_SET_ID                =     :P_ELEMENT_SET_ID      
                     or      :P_ELEMENT_SET_ID is null      
                    )
                  )  
            and  (
                 pet.ELEMENT_TYPE_ID             in
                   ( Select  per.ELEMENT_TYPE_ID 
                     from    PAY_ELEMENT_SETS_TL              pes
                            ,PAY_ELEMENT_TYPE_RULES           per
                     where   pes.ELEMENT_SET_ID                =             per.ELEMENT_SET_ID    
                       and   pes.language                      =             'ESA'
                       and   pes.element_set_name             in              ('DEDUCCIONES_RECIBO' )
                       and   per.include_or_exclude            =              'I'
                    )    
                 or (  pet.CLASSIFICATION_ID              in 
                           (Select  per.CLASSIFICATION_ID
                             from    PAY_ELEMENT_SETS_TL              pes
                                    ,PAY_ELE_CLASSIFICATION_RULES     per
                             where   pes.ELEMENT_SET_ID                =             per.ELEMENT_SET_ID    
                               and   pes.language                      =             'ESA'
                               and   pes.element_set_name             in              ('DEDUCCIONES_RECIBO')
                            ) 
                          and pet.ELEMENT_TYPE_ID        not      in
                           ( Select  per.ELEMENT_TYPE_ID 
                             from    PAY_ELEMENT_SETS_TL              pes
                                    ,PAY_ELEMENT_TYPE_RULES           per
                             where   pes.ELEMENT_SET_ID                =             per.ELEMENT_SET_ID    
                               and   pes.language                      =             'ESA'
                               and   pes.element_set_name             in               ('DEDUCCIONES_RECIBO')
                               and   per.include_or_exclude            =              'E'
                            ) 
                       )
                   )  
            and    paa.payroll_action_id                           = :P_PAYROLL_ACTION_ID    
            and    ppe.person_id                          = :p_PERSON_ID
            --and    ptp.time_period_id     = :p_TIME_PERIOD_ID
 Union all
            Select --pay.payroll_id,
            ptp.time_period_id 
                  ,ppe.person_id
                  ,upper(petl.reporting_name) Concepto,
 sum(to_number(prv.result_value))over (partition by petl.reporting_name) over_by,
                  ptp.REGULAR_PAYMENT_DATE
--                  ,to_number(prv.result_value*-1)         importe
--                  ,to_number(prv.result_value*-1)     importe_deducciones
                  ,pet.element_type_id
                  ,(Select to_number(prrd.result_value)
                    From   pay_run_result_values  prrd
                          ,pay_input_values_f     pivd    
                    where  prrd.run_result_id  = prr.run_result_id
                    and    prrd.INPUT_VALUE_ID = pivd.INPUT_VALUE_ID
                    and    pivd.name           in ('Days', 'Hours', 'Dias Trabajados')
                    )  dias
                            ,nvl( (SELECT 
            RRV.RESULT_VALUE
            FROM   HR_LOOKUPS LO1,
            HR_LOOKUPS LO2,
            PAY_INPUT_VALUES_F INV,
            PAY_INPUT_VALUES_F_TL INVTL,
            PAY_RUN_RESULT_VALUES RRV
    WHERE       INV.INPUT_VALUE_ID = INVTL.INPUT_VALUE_ID
            AND INVTL.LANGUAGE = USERENV ('LANG')
            AND RRV.INPUT_VALUE_ID = INV.INPUT_VALUE_ID /* DECODE NON-USER ENTERABLE TO NOT MANDATORY */
            --and RRV.INPUT_VALUE_ID in(1667,1666)
            --and RRV.INPUT_VALUE_ID=1666--efe
            and invtl.name='ISR Subject'--efe
            AND LO1.LOOKUP_TYPE = 'YES_NO'
            AND LO1.LOOKUP_CODE =
              DECODE (INV.MANDATORY_FLAG, 'X', 'N', INV.MANDATORY_FLAG)
            AND LO2.LOOKUP_TYPE = 'UNITS'
            AND LO2.LOOKUP_CODE = INV.UOM
            and  (RRV.RUN_RESULT_ID = pRV.RUN_RESULT_ID--13831862
            )),0) gravado,
            nvl((SELECT 
            RRV.RESULT_VALUE
            FROM   HR_LOOKUPS LO1,
            HR_LOOKUPS LO2,
            PAY_INPUT_VALUES_F INV,
            PAY_INPUT_VALUES_F_TL INVTL,
            PAY_RUN_RESULT_VALUES RRV
    WHERE       INV.INPUT_VALUE_ID = INVTL.INPUT_VALUE_ID
            AND INVTL.LANGUAGE = USERENV ('LANG')
            AND RRV.INPUT_VALUE_ID = INV.INPUT_VALUE_ID /* DECODE NON-USER ENTERABLE TO NOT MANDATORY */
            --and RRV.INPUT_VALUE_ID in(1667,1666)
            --and RRV.INPUT_VALUE_ID=1667--efe
            and invtl.name='ISR Exempt'--efe
            AND LO1.LOOKUP_TYPE = 'YES_NO'
            AND LO1.LOOKUP_CODE =
              DECODE (INV.MANDATORY_FLAG, 'X', 'N', INV.MANDATORY_FLAG)
            AND LO2.LOOKUP_TYPE = 'UNITS'
            AND LO2.LOOKUP_CODE = INV.UOM
            and  (RRV.RUN_RESULT_ID = pRV.RUN_RESULT_ID--13831862
            )),0) exento
            from   pay_run_results                  prr
                  ,pay_run_result_values            prv
                  ,pay_element_types_f              pet
                  ,pay_element_types_f_tl           petl
                  ,pay_assignment_actions           paa
                  ,pay_payroll_actions              ppa
                  ,per_time_periods                 ptp
                  ,per_all_assignments_f            pas    
                  ,per_all_people_f                 ppe   ---ok 
                  ,pay_all_payrolls_f               pay   ---ok
                  ,pay_element_classifications      pec   ---ok
            --      ,PAY_ELEMENT_SETS_TL              pes
            --      ,PAY_ELEMENT_TYPE_RULES           per
                  ,pay_input_values_f               piv
            Where  1=1
            and    prr.RUN_RESULT_ID                 =             prv.RUN_RESULT_ID
            and    prr.ELEMENT_TYPE_ID               =             pet.ELEMENT_TYPE_ID
            and    pet.ELEMENT_TYPE_ID               =             petl.ELEMENT_TYPE_ID
            and    petl.language                     =             'ESA'
            and    prr.ASSIGNMENT_ACTION_ID          =             paa.ASSIGNMENT_ACTION_ID
            and    ppa.PAYROLL_ACTION_ID             =             paa.PAYROLL_ACTION_ID    
            and    prv.INPUT_VALUE_ID                =             piv.INPUT_VALUE_ID
            and    piv.name                           in           ('Pay Value')       ---      ('ISR Subject','ISR Exempt')
            and    prv.result_value  <> '0'
            --and    ppa.BUSINESS_GROUP_ID             =             81   
            and    pet.CLASSIFICATION_ID             =             pec.CLASSIFICATION_ID   
            and    paa.ASSIGNMENT_ID                 =             pas.ASSIGNMENT_ID  
            and    ppa.TIME_PERIOD_ID                =             ptp.TIME_PERIOD_ID 
            and    ppa.PAYROLL_ID                    =             pay.PAYROLL_ID
            and    pas.PERSON_ID                     =             ppe.PERSON_ID 
            and    (ptp.REGULAR_PAYMENT_DATE        >=             pet.EFFECTIVE_START_DATE and ptp.REGULAR_PAYMENT_DATE   <= pet.EFFECTIVE_END_DATE) 
            and    (ptp.REGULAR_PAYMENT_DATE        >=             pas.EFFECTIVE_START_DATE and ptp.REGULAR_PAYMENT_DATE   <= pas.EFFECTIVE_END_DATE) 
            and    (ptp.REGULAR_PAYMENT_DATE        >=             ppe.EFFECTIVE_START_DATE and ptp.REGULAR_PAYMENT_DATE   <= ppe.EFFECTIVE_END_DATE) 
            and    (ptp.REGULAR_PAYMENT_DATE        >=             pay.EFFECTIVE_START_DATE and ptp.REGULAR_PAYMENT_DATE   <= pay.EFFECTIVE_END_DATE)
            and  (  pet.ELEMENT_TYPE_ID              in
                   ( Select  per.ELEMENT_TYPE_ID 
                     from    PAY_ELEMENT_TYPE_RULES           per
                     where   per.ELEMENT_SET_ID                =     :P_ELEMENT_SET_ID      
                     or      :P_ELEMENT_SET_ID is null      
                    )
                  )  
            and  (
                 pet.ELEMENT_TYPE_ID             in
                   ( Select  per.ELEMENT_TYPE_ID 
                     from    PAY_ELEMENT_SETS_TL              pes
                            ,PAY_ELEMENT_TYPE_RULES           per
                     where   pes.ELEMENT_SET_ID                =             per.ELEMENT_SET_ID    
                       and   pes.language                      =             'ESA'
                       and   pes.element_set_name             in              ('PERCEPCIONES NEGATIVAS_RECIBO' )
                       and   per.include_or_exclude            =              'I'
                    )    
                 or (  pet.CLASSIFICATION_ID              in 
                           (Select  per.CLASSIFICATION_ID
                             from    PAY_ELEMENT_SETS_TL              pes
                                    ,PAY_ELE_CLASSIFICATION_RULES     per
                             where   pes.ELEMENT_SET_ID                =             per.ELEMENT_SET_ID    
                               and   pes.language                      =             'ESA'
                               and   pes.element_set_name             in              ('PERCEPCIONES NEGATIVAS_RECIBO')
                            ) 
                          and pet.ELEMENT_TYPE_ID        not      in
                           ( Select  per.ELEMENT_TYPE_ID 
                             from    PAY_ELEMENT_SETS_TL              pes
                                    ,PAY_ELEMENT_TYPE_RULES           per
                             where   pes.ELEMENT_SET_ID                =             per.ELEMENT_SET_ID    
                               and   pes.language                      =             'ESA'
                               and   pes.element_set_name             in               ('PERCEPCIONES NEGATIVAS_RECIBO')
                               and   per.include_or_exclude            =              'E'
                            ) 
                       )
                   )  
            and    paa.payroll_action_id                           = :P_PAYROLL_ACTION_ID    
            and    ppe.person_id                          = :p_PERSON_ID





           Group by pet.element_type_id--efe
                    ,pay.payroll_id 
                  ,ptp.time_period_id 
                  ,ppe.person_id
                  ,nvl(to_number(pet.attribute1),1000) 
                  --,upper(petl.reporting_name)
                  ,petl.reporting_name  
                  ,ptp.REGULAR_PAYMENT_DATE
                  ,prv.result_value--efe
                  ,prr.run_result_id
                  ,pRV.RUN_RESULT_ID
                  
 

           Union all
            Select pay.payroll_id 
                  ,ptp.time_period_id 
                  ,ppe.person_id
                  ,upper(petl.reporting_name) Concepto
                  ,ptp.REGULAR_PAYMENT_DATE
                  ,to_number(prv.result_value*-1)         importe
                  ,to_number(prv.result_value*-1)     importe_deducciones
                  ,pet.element_type_id
                  ,(Select to_number(prrd.result_value)
                    From   pay_run_result_values  prrd
                          ,pay_input_values_f     pivd    
                    where  prrd.run_result_id  = prr.run_result_id
                    and    prrd.INPUT_VALUE_ID = pivd.INPUT_VALUE_ID
                    and    pivd.name           in ('Days', 'Hours', 'Dias Trabajados')
                    )  dias
                            ,nvl( (SELECT 
            RRV.RESULT_VALUE
            FROM   HR_LOOKUPS LO1,
            HR_LOOKUPS LO2,
            PAY_INPUT_VALUES_F INV,
            PAY_INPUT_VALUES_F_TL INVTL,
            PAY_RUN_RESULT_VALUES RRV
    WHERE       INV.INPUT_VALUE_ID = INVTL.INPUT_VALUE_ID
            AND INVTL.LANGUAGE = USERENV ('LANG')
            AND RRV.INPUT_VALUE_ID = INV.INPUT_VALUE_ID /* DECODE NON-USER ENTERABLE TO NOT MANDATORY */
            --and RRV.INPUT_VALUE_ID in(1667,1666)
            and RRV.INPUT_VALUE_ID=1666--efe
            AND LO1.LOOKUP_TYPE = 'YES_NO'
            AND LO1.LOOKUP_CODE =
              DECODE (INV.MANDATORY_FLAG, 'X', 'N', INV.MANDATORY_FLAG)
            AND LO2.LOOKUP_TYPE = 'UNITS'
            AND LO2.LOOKUP_CODE = INV.UOM
            and  (RRV.RUN_RESULT_ID = pRV.RUN_RESULT_ID--13831862
            )),0) gravado,
            nvl((SELECT 
            RRV.RESULT_VALUE
            FROM   HR_LOOKUPS LO1,
            HR_LOOKUPS LO2,
            PAY_INPUT_VALUES_F INV,
            PAY_INPUT_VALUES_F_TL INVTL,
            PAY_RUN_RESULT_VALUES RRV
    WHERE       INV.INPUT_VALUE_ID = INVTL.INPUT_VALUE_ID
            AND INVTL.LANGUAGE = USERENV ('LANG')
            AND RRV.INPUT_VALUE_ID = INV.INPUT_VALUE_ID /* DECODE NON-USER ENTERABLE TO NOT MANDATORY */
            --and RRV.INPUT_VALUE_ID in(1667,1666)
            and RRV.INPUT_VALUE_ID=1667--efe
            AND LO1.LOOKUP_TYPE = 'YES_NO'
            AND LO1.LOOKUP_CODE =
              DECODE (INV.MANDATORY_FLAG, 'X', 'N', INV.MANDATORY_FLAG)
            AND LO2.LOOKUP_TYPE = 'UNITS'
            AND LO2.LOOKUP_CODE = INV.UOM
            and  (RRV.RUN_RESULT_ID = pRV.RUN_RESULT_ID--13831862
            )),0) exento
            from   pay_run_results                  prr
                  ,pay_run_result_values            prv
                  ,pay_element_types_f              pet
                  ,pay_element_types_f_tl           petl
                  ,pay_assignment_actions           paa
                  ,pay_payroll_actions              ppa
                  ,per_time_periods                 ptp
                  ,per_all_assignments_f            pas    
                  ,per_all_people_f                 ppe   ---ok 
                  ,pay_all_payrolls_f               pay   ---ok
                  ,pay_element_classifications      pec   ---ok
            --      ,PAY_ELEMENT_SETS_TL              pes
            --      ,PAY_ELEMENT_TYPE_RULES           per
                  ,pay_input_values_f               piv
            Where  1=1
            and    prr.RUN_RESULT_ID                 =             prv.RUN_RESULT_ID
            and    prr.ELEMENT_TYPE_ID               =             pet.ELEMENT_TYPE_ID
            and    pet.ELEMENT_TYPE_ID               =             petl.ELEMENT_TYPE_ID
            and    petl.language                     =             'ESA'
            and    prr.ASSIGNMENT_ACTION_ID          =             paa.ASSIGNMENT_ACTION_ID
            and    ppa.PAYROLL_ACTION_ID             =             paa.PAYROLL_ACTION_ID    
            and    prv.INPUT_VALUE_ID                =             piv.INPUT_VALUE_ID
            and    piv.name                           in           ('Pay Value')       ---      ('ISR Subject','ISR Exempt')
            and    prv.result_value  <> '0'
            --and    ppa.BUSINESS_GROUP_ID             =             81   
            and    pet.CLASSIFICATION_ID             =             pec.CLASSIFICATION_ID   
            and    paa.ASSIGNMENT_ID                 =             pas.ASSIGNMENT_ID  
            and    ppa.TIME_PERIOD_ID                =             ptp.TIME_PERIOD_ID 
            and    ppa.PAYROLL_ID                    =             pay.PAYROLL_ID
            and    pas.PERSON_ID                     =             ppe.PERSON_ID 
            and    (ptp.REGULAR_PAYMENT_DATE        >=             pet.EFFECTIVE_START_DATE and ptp.REGULAR_PAYMENT_DATE   <= pet.EFFECTIVE_END_DATE) 
            and    (ptp.REGULAR_PAYMENT_DATE        >=             pas.EFFECTIVE_START_DATE and ptp.REGULAR_PAYMENT_DATE   <= pas.EFFECTIVE_END_DATE) 
            and    (ptp.REGULAR_PAYMENT_DATE        >=             ppe.EFFECTIVE_START_DATE and ptp.REGULAR_PAYMENT_DATE   <= ppe.EFFECTIVE_END_DATE) 
            and    (ptp.REGULAR_PAYMENT_DATE        >=             pay.EFFECTIVE_START_DATE and ptp.REGULAR_PAYMENT_DATE   <= pay.EFFECTIVE_END_DATE)
            and  (  pet.ELEMENT_TYPE_ID              in
                   ( Select  per.ELEMENT_TYPE_ID 
                     from    PAY_ELEMENT_TYPE_RULES           per
                     where   per.ELEMENT_SET_ID                =     :P_ELEMENT_SET_ID      
                     or      :P_ELEMENT_SET_ID is null      
                    )
                  )  
            and  (
                 pet.ELEMENT_TYPE_ID             in
                   ( Select  per.ELEMENT_TYPE_ID 
                     from    PAY_ELEMENT_SETS_TL              pes
                            ,PAY_ELEMENT_TYPE_RULES           per
                     where   pes.ELEMENT_SET_ID                =             per.ELEMENT_SET_ID    
                       and   pes.language                      =             'ESA'
                       and   pes.element_set_name             in              ('PERCEPCIONES NEGATIVAS_RECIBO' )
                       and   per.include_or_exclude            =              'I'
                    )    
                 or (  pet.CLASSIFICATION_ID              in 
                           (Select  per.CLASSIFICATION_ID
                             from    PAY_ELEMENT_SETS_TL              pes
                                    ,PAY_ELE_CLASSIFICATION_RULES     per
                             where   pes.ELEMENT_SET_ID                =             per.ELEMENT_SET_ID    
                               and   pes.language                      =             'ESA'
                               and   pes.element_set_name             in              ('PERCEPCIONES NEGATIVAS_RECIBO')
                            ) 
                          and pet.ELEMENT_TYPE_ID        not      in
                           ( Select  per.ELEMENT_TYPE_ID 
                             from    PAY_ELEMENT_SETS_TL              pes
                                    ,PAY_ELEMENT_TYPE_RULES           per
                             where   pes.ELEMENT_SET_ID                =             per.ELEMENT_SET_ID    
                               and   pes.language                      =             'ESA'
                               and   pes.element_set_name             in               ('PERCEPCIONES NEGATIVAS_RECIBO')
                               and   per.include_or_exclude            =              'E'
                            ) 
                       )
                   )  
            and    paa.payroll_action_id                           = :P_PAYROLL_ACTION_ID    
            and    ppe.person_id                          = :p_PERSON_ID
            and    ptp.time_period_id     = :p_TIME_PERIOD_ID
            Group by --pay.payroll_id 
--                  ,ptp.time_period_id 
--                  ,ppe.person_id
--                  nvl(to_number(pet.attribute1),1000) 
--                  ,upper(petl.reporting_name)  
--                  ,ptp.REGULAR_PAYMENT_DATE
--                  ,pet.element_type_id
 -           order by 4;
 