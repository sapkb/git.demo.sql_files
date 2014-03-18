  -------------horas extras 
  
  SELECT   --pet.*
  pet.element_type_id,prv.result_value importe_pagado,---- horas extras, 
                       pay.payroll_id,
                       ptp.time_period_id,
                       ppe.person_id,
                       UPPER (petl.reporting_name) Concepto,-- tipo_HORAS
                      -- SUM (TO_NUMBER (prv.result_value)) importe,--importe incapacidad
                       SUM( (SELECT   TO_NUMBER (prrd.result_value)
                               FROM   pay_run_result_values prrd,
                                      pay_input_values_f pivd
                              WHERE   prrd.run_result_id = prr.run_result_id
                                      AND prrd.INPUT_VALUE_ID =
                                            pivd.INPUT_VALUE_ID
                                      AND pivd.name IN
                                               ('Hours'--'Days',
                                               -- 'Hours'
                                                --'Dias Trabajados'
                                                )))
                         horas_extras--dias incapacidad(1 hora=1 dia, entre 1 y 2 horas=2 dias, mas de 2 horas=3 dias)  
                         ,pet.element_type_id
                FROM   pay_run_results prr,
                       pay_run_result_values prv,
                       pay_element_types_f pet,
                       pay_element_types_f_tl petl,
                       pay_assignment_actions paa,
                       pay_payroll_actions ppa,
                       per_time_periods ptp,
                       per_all_assignments_f pas,
                       per_all_people_f ppe                              ---ok
                                           ,
                       pay_all_payrolls_f pay                            ---ok
                                             ,
                       pay_element_classifications pec                   ---ok
                                                      --      ,PAY_ELEMENT_SETS_TL              pes
                                                      --      ,PAY_ELEMENT_TYPE_RULES           per
                       ,
                       pay_input_values_f piv
               WHERE       1 = 1
                       AND prr.RUN_RESULT_ID = prv.RUN_RESULT_ID
                       AND prr.ELEMENT_TYPE_ID = pet.ELEMENT_TYPE_ID
                       AND pet.ELEMENT_TYPE_ID = petl.ELEMENT_TYPE_ID
                       AND petl.language = 'ESA'
                       AND prr.ASSIGNMENT_ACTION_ID = paa.ASSIGNMENT_ACTION_ID
                       AND ppa.PAYROLL_ACTION_ID = paa.PAYROLL_ACTION_ID
                       AND prv.INPUT_VALUE_ID = piv.INPUT_VALUE_ID
                       --AND piv.name IN ('Pay Value') --- ('ISR Subject','ISR Exempt')
                       --and    ppa.BUSINESS_GROUP_ID             =             81
                       AND pet.CLASSIFICATION_ID = pec.CLASSIFICATION_ID
                       AND paa.ASSIGNMENT_ID = pas.ASSIGNMENT_ID
                       AND ppa.TIME_PERIOD_ID = ptp.TIME_PERIOD_ID
                       AND ppa.PAYROLL_ID = pay.PAYROLL_ID
                       AND pas.PERSON_ID = ppe.PERSON_ID
                       AND (ptp.REGULAR_PAYMENT_DATE >= pet.EFFECTIVE_START_DATE
                            AND ptp.REGULAR_PAYMENT_DATE <=
                                  pet.EFFECTIVE_END_DATE)
                       AND (ptp.REGULAR_PAYMENT_DATE >= pas.EFFECTIVE_START_DATE
                            AND ptp.REGULAR_PAYMENT_DATE <=
                                  pas.EFFECTIVE_END_DATE)
                       AND (ptp.REGULAR_PAYMENT_DATE >= ppe.EFFECTIVE_START_DATE
                            AND ptp.REGULAR_PAYMENT_DATE <=
                                  ppe.EFFECTIVE_END_DATE)
                       AND (ptp.REGULAR_PAYMENT_DATE >= pay.EFFECTIVE_START_DATE
                            AND ptp.REGULAR_PAYMENT_DATE <=
                                  pay.EFFECTIVE_END_DATE)
                      AND ( petl.element_name like 'P1290 TIEMPO EXTRA DOBLE' or petl.element_name like 'P1300 TIEMPO EXTRA TRIPLE')
                       --AND paa.payroll_action_id = :P_PAYROLL_ACTION_ID --162847
                       --AND ppe.person_id = :p_PERSON_ID                --11069
                      --AND ptp.time_period_id = :p_TIME_PERIOD_ID       --5698
                      --and (pet.element_name like '%INCAP%ENFERMEDAD' or pet.element_name like '%INCAP%MATERNIDAD')
              GROUP BY   petl.element_name,pay.payroll_id,
                       ptp.time_period_id,
                       ppe.person_id,
                       --NVL (TO_NUMBER (pet.attribute1), 1000),
                       UPPER (petl.reporting_name),
                       ptp.REGULAR_PAYMENT_DATE,
                       pet.element_type_id,
                       pRV.RUN_RESULT_ID,
                       prv.result_value
               ORDER BY petl.element_name
                       
  -----------------------------indemnisaciones
                      
  SELECT   --pet.*
  pet.element_type_id,prv.result_value importe_pagado,---- horas extras, 
                       pay.payroll_id,
                       ptp.time_period_id,
                       ppe.person_id,
                       UPPER (petl.reporting_name) Concepto,-- tipo incapacidad
                      SUM (TO_NUMBER (prv.result_value)) importe,--importe incapacidad
                       SUM( (SELECT   TO_NUMBER (prrd.result_value)
                               FROM   pay_run_result_values prrd,
                                      pay_input_values_f pivd
                              WHERE   prrd.run_result_id = prr.run_result_id
                                      AND prrd.INPUT_VALUE_ID =
                                            pivd.INPUT_VALUE_ID
                                      AND pivd.name IN
                                               ('Days',
                                                'Hours',
                                                'Dias Trabajados'
                                                )))
                         dias --incapacidad(1 hora=1 dia, entre 1 y 2 horas=2 dias, mas de 2 horas=3 dias)  
                         ,pet.element_type_id
                FROM   pay_run_results prr,
                       pay_run_result_values prv,
                       pay_element_types_f pet,
                       pay_element_types_f_tl petl,
                       pay_assignment_actions paa,
                       pay_payroll_actions ppa,
                       per_time_periods ptp,
                       per_all_assignments_f pas,
                       per_all_people_f ppe                              ---ok
                                           ,
                       pay_all_payrolls_f pay                            ---ok
                                             ,
                       pay_element_classifications pec                   ---ok
                                                      --      ,PAY_ELEMENT_SETS_TL              pes
                                                      --      ,PAY_ELEMENT_TYPE_RULES           per
                       ,
                       pay_input_values_f piv
               WHERE       1 = 1
                       AND prr.RUN_RESULT_ID = prv.RUN_RESULT_ID
                       AND prr.ELEMENT_TYPE_ID = pet.ELEMENT_TYPE_ID
                       AND pet.ELEMENT_TYPE_ID = petl.ELEMENT_TYPE_ID
                       AND petl.language = 'ESA'
                       AND prr.ASSIGNMENT_ACTION_ID = paa.ASSIGNMENT_ACTION_ID
                       AND ppa.PAYROLL_ACTION_ID = paa.PAYROLL_ACTION_ID
                       AND prv.INPUT_VALUE_ID = piv.INPUT_VALUE_ID
                       --AND piv.name IN ('Pay Value') --- ('ISR Subject','ISR Exempt')
                       --and    ppa.BUSINESS_GROUP_ID             =             81
                       AND pet.CLASSIFICATION_ID = pec.CLASSIFICATION_ID
                       AND paa.ASSIGNMENT_ID = pas.ASSIGNMENT_ID
                       AND ppa.TIME_PERIOD_ID = ptp.TIME_PERIOD_ID
                       AND ppa.PAYROLL_ID = pay.PAYROLL_ID
                       AND pas.PERSON_ID = ppe.PERSON_ID
                       AND (ptp.REGULAR_PAYMENT_DATE >= pet.EFFECTIVE_START_DATE
                            AND ptp.REGULAR_PAYMENT_DATE <=
                                  pet.EFFECTIVE_END_DATE)
                       AND (ptp.REGULAR_PAYMENT_DATE >= pas.EFFECTIVE_START_DATE
                            AND ptp.REGULAR_PAYMENT_DATE <=
                                  pas.EFFECTIVE_END_DATE)
                       AND (ptp.REGULAR_PAYMENT_DATE >= ppe.EFFECTIVE_START_DATE
                            AND ptp.REGULAR_PAYMENT_DATE <=
                                  ppe.EFFECTIVE_END_DATE)
                       AND (ptp.REGULAR_PAYMENT_DATE >= pay.EFFECTIVE_START_DATE
                            AND ptp.REGULAR_PAYMENT_DATE <=
                                  pay.EFFECTIVE_END_DATE)
                      --AND ( petl.element_name like 'P1290 TIEMPO EXTRA DOBLE' or petl.element_name like 'P1300 TIEMPO EXTRA TRIPLE')
                         --and petl.element_type_id=446
                       AND paa.payroll_action_id = :P_PAYROLL_ACTION_ID --162847
                       AND ppe.person_id = :p_PERSON_ID                --11069
                      aND ptp.time_period_id = :p_TIME_PERIOD_ID       --5698
                      and (pet.element_name like '%INCAP%ENFERMEDAD' or pet.element_name like '%INCAP%MATERNIDAD')
              GROUP BY   pay.payroll_id,
                       ptp.time_period_id,
                       ppe.person_id,
                      NVL (TO_NUMBER (pet.attribute1), 1000),
                       UPPER (petl.reporting_name),
                       ptp.REGULAR_PAYMENT_DATE,
                       pet.element_type_id,
                       pRV.RUN_RESULT_ID,
                       prv.result_value