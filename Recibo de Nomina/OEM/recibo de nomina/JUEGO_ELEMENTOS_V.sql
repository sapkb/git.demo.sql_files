SELECT t.element_set_name, t.element_set_id 
FROM pay_element_sets e,pay_element_sets_tl t,per_business_groups_perf p
where (( e.business_group_id = p.business_group_id
  ) or ( e.legislation_code = p.legislation_code ) or ( e.business_group_id is
  null and e.legislation_code is null ) ) and element_set_type = 'R' 
  --and  p.business_group_id = :$PROFILES$.PER_BUSINESS_GROUP_ID 
  and
  e.element_set_id=t.element_set_id and t.language=userenv('LANG') order by
  e.element_set_name
  
  SELECT * FROM pay_RUN_RESULTS
  
  SELECT DISTINCT PESTL.element_set_name, PESTL.element_set_id  
  FROM pay_payroll_actions PPA, pay_element_sets PES ,pay_element_sets_tl PESTL
  WHERE  1=1
  AND PPA.ELEMENT_SET_ID=PES.ELEMENT_SET_ID
  AND    PES.element_set_id=PESTL.element_set_id and PESTL.language=userenv('LANG')
    
  SELECT * FROM pay_element_types_f 
  
  SELECT * FROM pay_element_sets
  
------------------------------------------------------------query v1-----------------------  
  
  Select  pay.payroll_id id_nomina,prr.RUN_RESULT_ID, 
                --pay.PAYROLL_NAME, 
                --ppe.person_id, 
          ppe.EMPLOYEE_NUMBER numero_empleado,
          sysdate fecha_pago, 
          ptp.START_DATE fecha_inicial, 
          ptp.CUT_OFF_DATE fecha_final,
                 (SELECT pbvv2.VALUE
                  FROM   pay_balance_values_v pbvv2
                  WHERE      pbvv2.business_group_id = 81
                  AND (pbvv2.ASSIGNMENT_ACTION_ID =paa.ASSIGNMENT_ACTION_ID-- 3743833
                         )
                  AND (pbvv2.DEFINED_BALANCE_ID = APPS.XXOEM_RECIBOS_ELECTRONICOS_PKG.P_DEFINED_BALANCE_ID(paa.ASSIGNMENT_ACTION_ID)--21724
                    )) dias_pagados,
          '0' salario_Base_Cot,PRV.RESULT_VALUE SDI,PESTL.element_set_name decripcion,
           ppe.FULL_NAME,
           ptp.time_period_id,
           ppe.person_id   
                --ptp.time_period_id, 
                --ptp.PERIOD_NAME, 
                --ppe.PER_INFORMATION2                        RFC, 
                --ppe.PER_INFORMATION3                        IMSS, 
               -- ppe.NATIONAL_IDENTIFIER  CURP,
               -- substr(aou.name, instr(aou.name,' ',1,2)+1) DEPARTAMENTO, 
                --ppd.SEGMENT3                                PUESTO,  
                --hoi.ORG_INFORMATION1                        Compania, 
                --hoi.ORG_INFORMATION2                        RFC_CIA, 
--                pas.PAY_BASIS_ID, 
--                pas.GRADE_ID, 
--                pas.Assignment_id, 
--                ppa.ELEMENT_SET_ID,  
--                paa.ASSIGNMENT_ACTION_ID,------- usar
--               -- hlo.location_code, 
--               paa.payroll_action_id,  
               -- to_char(ptp.START_DATE,'dd')                per_ini,
--               to_char(ptp.START_DATE,'dd mon yyyy')     per_ini,  
--                to_char(ptp.CUT_OFF_DATE,'dd mon yyyy')     per_fin 
--               -- ptp.                                        period_num,
               -- ppg.SEGMENT1                                division, 
              --  pca.segment6                                centro_costos, 
              --  pca.segment7                                depto, 
              --  PAS.SOFT_CODING_KEYFLEX_ID,
                --PESTL.element_set_name decripcion,'0' salario_Base_Cot,PRV.RESULT_VALUE SDI
        from   pay_run_results                  prr
              ,pay_run_result_values            prv
              ,pay_element_types_f              pet
              ,pay_assignment_actions           paa
              ,pay_payroll_actions              ppa
              ,per_time_periods                 ptp
              ,per_position_definitions         ppd
              ,per_assignments_f2               pas 
              ,per_all_people_f                 ppe
              ,pay_all_payrolls_f               pay
              ,hr_soft_coding_keyflex           sck
              ,hr_all_organization_units        aou
              ,per_all_positions                pjb
              ,per_gen_hierarchy                pgh
              ,per_gen_hierarchy_versions       pgv
              ,per_gen_hierarchy_nodes          pgn
              ,per_gen_hierarchy_nodes          pgnp 
              ,hr_organization_information      hoi
               ,pay_input_values_f              piv
               ,hr_locations_all                hlo
               ,pay_people_groups               ppg  
               ,pay_cost_allocation_keyflex     pca
               ,pay_element_sets PES ,pay_element_sets_tl PESTL,---EFE
               PAY_ELEMENT_TYPES_F ETY,--efe
            PAY_ELEMENT_TYPES_F_TL ETYTL--efe
        Where  1=1
         and ETY.element_type_id = ETYTL.element_type_id--efe
         AND ETYTL.LANGUAGE = USERENV ('LANG')--efe
        AND PIV.ELEMENT_TYPE_ID = ETY.ELEMENT_TYPE_ID--efe
        AND PRR.ELEMENT_TYPE_ID = ETY.ELEMENT_TYPE_ID--efe
        AND  ETYTL.ELEMENT_NAME= 'I7001 SDI'
        and prr.RUN_RESULT_ID                =           prv.RUN_RESULT_ID
        and    prr.ELEMENT_TYPE_ID              =           pet.ELEMENT_TYPE_ID
        and    pjb.POSITION_DEFINITION_ID       =           ppd.POSITION_DEFINITION_ID
        and    prr.ASSIGNMENT_ACTION_ID         =           paa.ASSIGNMENT_ACTION_ID
        and    ppa.PAYROLL_ACTION_ID            =           paa.PAYROLL_ACTION_ID    
        and    pas.location_id                  =           hlo.location_id
        and    ppa.BUSINESS_GROUP_ID            =           pgh.BUSINESS_GROUP_ID   
        and    paa.ASSIGNMENT_ID                =           pas.ASSIGNMENT_ID  
        and    pas.PEOPLE_GROUP_ID              =           ppg.PEOPLE_GROUP_ID    ---add
        and    ppa.TIME_PERIOD_ID               =           ptp.TIME_PERIOD_ID 
        and    ppa.PAYROLL_ID                   =           pay.PAYROLL_ID
        and    pas.PERSON_ID                    =           ppe.PERSON_ID 
        and    prv.INPUT_VALUE_ID               =           piv.INPUT_VALUE_ID
        and    piv.name                         in          ('Pay Value','ISR Subject','ISR Exempt')
        and    prv.result_value                 >           '0'
        AND    PAS.SOFT_CODING_KEYFLEX_ID       =           SCK.SOFT_CODING_KEYFLEX_ID
        AND    PAS.ORGANIZATION_ID              =           AOU.ORGANIZATION_ID
        and    aou.COST_ALLOCATION_KEYFLEX_ID   =           pca.COST_ALLOCATION_KEYFLEX_ID
        AND    PAS.POSITION_ID                  =           PJB.POSITION_ID (+)
        AND    pgn.ENTITY_ID      (+)           =           SCK.SEGMENT1
        and   (ptp.REGULAR_PAYMENT_DATE         >=          pet.EFFECTIVE_START_DATE 
            and ptp.REGULAR_PAYMENT_DATE        <=          pet.EFFECTIVE_END_DATE
                ) 
        and   (ptp.REGULAR_PAYMENT_DATE         >=          pas.EFFECTIVE_START_DATE 
            and ptp.REGULAR_PAYMENT_DATE        <=          pas.EFFECTIVE_END_DATE
                ) 
        and   (ptp.REGULAR_PAYMENT_DATE         >=          ppe.EFFECTIVE_START_DATE 
            and ptp.REGULAR_PAYMENT_DATE        <=          ppe.EFFECTIVE_END_DATE
                ) 
        and   (ptp.REGULAR_PAYMENT_DATE         >=          pay.EFFECTIVE_START_DATE 
            and ptp.REGULAR_PAYMENT_DATE        <=          pay.EFFECTIVE_END_DATE
                )
        AND    pgh.HIERARCHY_ID                 =           pgv.HIERARCHY_ID
        and    pgv.HIERARCHY_VERSION_ID         =           pgn.HIERARCHY_VERSION_ID
        and    pgh.type                         =           'MEXICO HRMS'
        and    pgv.DATE_FROM                    <=          sysdate
        and    nvl(pgv.DATE_TO,sysdate)         >=          sysdate   
        and    pgn.NODE_TYPE                    =           'MX GRE'     
        and    pgnp.NODE_TYPE                   =           'MX LEGAL EMPLOYER'   
        and    pgn.PARENT_HIERARCHY_NODE_ID     =           pgnp.HIERARCHY_NODE_ID  
        and    hoi.ORGANIZATION_ID              =           pgnp.ENTITY_ID
        and    hoi.ORG_INFORMATION_CONTEXT      =           'MX_TAX_REGISTRATION'
        and    paa.payroll_action_id            =           :P_PAYROLL_ACTION_ID  
        and   (ppa.ELEMENT_SET_ID               =           :P_ELEMENT_SET_ID  
            or :P_ELEMENT_SET_ID                 is          null
                )
        and   (ppg.SEGMENT1                     =           :P_DIVISION  
            or :P_DIVISION                       is          null
                )
        and   (pca.segment6                     =           :P_CENTRO_COSTOS  
            or :P_CENTRO_COSTOS                  is          null
                )
        and   (pca.segment7                     =           :P_DEPARTAMENTO  
            or :P_DEPARTAMENTO                   is          null
                )
        and   (ppe.person_id                    =           :P_PERSON_ID  
            or :P_PERSON_ID                      is          null
                )
        and    ppe.EMPLOYEE_NUMBER              >=          NVL(:P_EMP_NUM_INI,ppe.EMPLOYEE_NUMBER)
        and    ppe.EMPLOYEE_NUMBER              <=          NVL(:P_EMP_NUM_FIN,ppe.EMPLOYEE_NUMBER)
        and    hlo.location_code                =           NVL(:P_LOCATION_CODE, hlo.location_code)
        AND    pgh.BUSINESS_GROUP_ID            =           apps.fnd_profile.VALUE('PER_BUSINESS_GROUP_ID')
        AND PPA.ELEMENT_SET_ID=PES.ELEMENT_SET_ID--EFE
       AND    PES.element_set_id=PESTL.element_set_id and PESTL.language=userenv('LANG')--EFE
        Group by pay.payroll_id, pay.PAYROLL_NAME, ppe.person_id, ppe.EMPLOYEE_NUMBER, ppe.FULL_NAME,   
               ptp.time_period_id, ptp.PERIOD_NAME, ppe.PER_INFORMATION2, ppe.PER_INFORMATION3, ppe.NATIONAL_IDENTIFIER, aou.NAME, ppd.SEGMENT3,  
               hoi.ORG_INFORMATION1, hoi.ORG_INFORMATION2, pas.PAY_BASIS_ID, pas.GRADE_ID, pas.GRADE_ID, pas.Assignment_id, ptp.START_DATE, ptp.CUT_OFF_DATE,
               ppa.ELEMENT_SET_ID,  paa.ASSIGNMENT_ACTION_ID, 
               hlo.location_code, paa.payroll_action_id, ptp.period_num,ppg.SEGMENT1, pca.segment6, pca.segment7,PAS.SOFT_CODING_KEYFLEX_ID,
               --efe
               PESTL.element_set_name,PRV.RESULT_VALUE,prr.RUN_RESULT_ID
               --EFE
        order by pay.PAYROLL_NAME, ptp.time_period_id,  hlo.location_code, ppe.FULL_NAME, ppe.EMPLOYEE_NUMBER;
          