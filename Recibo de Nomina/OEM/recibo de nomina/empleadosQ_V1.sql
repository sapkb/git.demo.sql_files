begin
  fnd_global.set_nls_context('LATIN AMERICAN SPANISH');
end;

  SELECT   pay.payroll_id id_nomina,
                    ppe.EMPLOYEE_NUMBER numero_empleado,               --listo
                    SYSDATE fecha_pago,
                    ptp.START_DATE fecha_inicial,
                    ptp.CUT_OFF_DATE fecha_final,
                    (SELECT   pbvv2.VALUE
                       FROM   pay_balance_values_v pbvv2
                      WHERE   pbvv2.business_group_id = 81
                              AND (pbvv2.ASSIGNMENT_ACTION_ID =
                                      paa.ASSIGNMENT_ACTION_ID      -- 3743833
                                                              )
                              AND (pbvv2.DEFINED_BALANCE_ID =
                                      APPS.XXOEM_RECIBOS_ELECTRONICOS_PKG.P_DEFINED_BALANCE_ID(paa.ASSIGNMENT_ACTION_ID) --21724
                                                                                                                        ))
                       dias_pagados,
                    '0' salario_Base_Cot,
                    PRV.RESULT_VALUE SDI,
                    PESTL.element_set_name decripcion,
                    ppe.FULL_NAME,
                    ptp.time_period_id,
                    ppe.person_id,                                     --listo
                    SUBSTR (aou.name, INSTR (aou.name,
                                             ' ',
                                             1,
                                             2)
                                      + 1)
                       DEPARTAMENTO,                                   --listo
                    ppa.ELEMENT_SET_ID,                                --listo
                    hlo.location_code,                                 --listo
                    paa.payroll_action_id,                             --listo
                    ppg.SEGMENT1 division,                             --listo
                    pca.segment6 centro_costos                         --listo
             FROM   pay_run_results prr,
                    pay_run_result_values prv,
                    pay_element_types_f pet,
                    pay_assignment_actions paa,
                    pay_payroll_actions ppa,
                    per_time_periods ptp,
                    per_position_definitions ppd,
                    per_assignments_f2 pas,
                    per_all_people_f ppe,
                    pay_all_payrolls_f pay,
                    hr_soft_coding_keyflex sck,
                    hr_all_organization_units aou,
                    per_all_positions pjb,
                    per_gen_hierarchy pgh,
                    per_gen_hierarchy_versions pgv,
                    per_gen_hierarchy_nodes pgn,
                    per_gen_hierarchy_nodes pgnp,
                    hr_organization_information hoi,
                    pay_input_values_f piv,
                    hr_locations_all hlo,
                    pay_people_groups ppg,
                    pay_cost_allocation_keyflex pca,
                    pay_element_sets PES,
                    pay_element_sets_tl PESTL,                          ---EFE
                    PAY_ELEMENT_TYPES_F ETY,                             --efe
                    PAY_ELEMENT_TYPES_F_TL ETYTL                         --efe
            WHERE       1 = 1
                    AND ETY.element_type_id = ETYTL.element_type_id      --efe
                    AND ETYTL.LANGUAGE = USERENV ('LANG')                --efe
                    AND PIV.ELEMENT_TYPE_ID = ETY.ELEMENT_TYPE_ID        --efe
                    AND PRR.ELEMENT_TYPE_ID = ETY.ELEMENT_TYPE_ID        --efe
                    AND ETYTL.ELEMENT_NAME = 'I7001 SDI'
                    AND prr.RUN_RESULT_ID = prv.RUN_RESULT_ID
                    AND prr.ELEMENT_TYPE_ID = pet.ELEMENT_TYPE_ID
                    AND pjb.POSITION_DEFINITION_ID = ppd.POSITION_DEFINITION_ID
                    AND prr.ASSIGNMENT_ACTION_ID = paa.ASSIGNMENT_ACTION_ID
                    AND ppa.PAYROLL_ACTION_ID = paa.PAYROLL_ACTION_ID
                    AND pas.location_id = hlo.location_id
                    AND ppa.BUSINESS_GROUP_ID = pgh.BUSINESS_GROUP_ID
                    AND paa.ASSIGNMENT_ID = pas.ASSIGNMENT_ID
                    AND pas.PEOPLE_GROUP_ID = ppg.PEOPLE_GROUP_ID       ---add
                    AND ppa.TIME_PERIOD_ID = ptp.TIME_PERIOD_ID
                    AND ppa.PAYROLL_ID = pay.PAYROLL_ID
                    AND pas.PERSON_ID = ppe.PERSON_ID
                    AND prv.INPUT_VALUE_ID = piv.INPUT_VALUE_ID
                    AND piv.name IN ('Pay Value', 'ISR Subject', 'ISR Exempt')
                    AND prv.result_value > '0'
                    AND PAS.SOFT_CODING_KEYFLEX_ID = SCK.SOFT_CODING_KEYFLEX_ID
                    AND PAS.ORGANIZATION_ID = AOU.ORGANIZATION_ID
                    AND aou.COST_ALLOCATION_KEYFLEX_ID =
                          pca.COST_ALLOCATION_KEYFLEX_ID
                    AND PAS.POSITION_ID = PJB.POSITION_ID(+)
                    AND pgn.ENTITY_ID(+) = SCK.SEGMENT1
                    AND (ptp.REGULAR_PAYMENT_DATE >= pet.EFFECTIVE_START_DATE
                         AND ptp.REGULAR_PAYMENT_DATE <= pet.EFFECTIVE_END_DATE)
                    AND (ptp.REGULAR_PAYMENT_DATE >= pas.EFFECTIVE_START_DATE
                         AND ptp.REGULAR_PAYMENT_DATE <= pas.EFFECTIVE_END_DATE)
                    AND (ptp.REGULAR_PAYMENT_DATE >= ppe.EFFECTIVE_START_DATE
                         AND ptp.REGULAR_PAYMENT_DATE <= ppe.EFFECTIVE_END_DATE)
                    AND (ptp.REGULAR_PAYMENT_DATE >= pay.EFFECTIVE_START_DATE
                         AND ptp.REGULAR_PAYMENT_DATE <= pay.EFFECTIVE_END_DATE)
                    AND pgh.HIERARCHY_ID = pgv.HIERARCHY_ID
                    AND pgv.HIERARCHY_VERSION_ID = pgn.HIERARCHY_VERSION_ID
                    AND pgh.TYPE = 'MEXICO HRMS'
                    AND pgv.DATE_FROM <= SYSDATE
                    AND NVL (pgv.DATE_TO, SYSDATE) >= SYSDATE
                    AND pgn.NODE_TYPE = 'MX GRE'
                    AND pgnp.NODE_TYPE = 'MX LEGAL EMPLOYER'
                    AND pgn.PARENT_HIERARCHY_NODE_ID = pgnp.HIERARCHY_NODE_ID
                    AND hoi.ORGANIZATION_ID = pgnp.ENTITY_ID
                    AND hoi.ORG_INFORMATION_CONTEXT = 'MX_TAX_REGISTRATION'
                    AND paa.payroll_action_id = :P_PAYROLL_ACTION_ID
                    AND (ppa.ELEMENT_SET_ID = :P_ELEMENT_SET_ID
                         OR :P_ELEMENT_SET_ID IS NULL)
                    AND (ppg.SEGMENT1 = :P_DIVISION OR :P_DIVISION IS NULL)
                    AND (pca.segment6 = :P_CENTRO_COSTOS
                         OR :P_CENTRO_COSTOS IS NULL)
                    AND (pca.segment7 = :P_DEPARTAMENTO
                         OR :P_DEPARTAMENTO IS NULL)
                    AND (ppe.person_id = :P_PERSON_ID OR :P_PERSON_ID IS NULL)
                    AND ppe.EMPLOYEE_NUMBER >=
                          NVL (:P_EMP_NUM_INI, ppe.EMPLOYEE_NUMBER)
                    AND ppe.EMPLOYEE_NUMBER <=
                          NVL (:P_EMP_NUM_FIN, ppe.EMPLOYEE_NUMBER)
                    AND hlo.location_code =
                          NVL (:P_LOCATION_CODE, hlo.location_code)
                    AND pgh.BUSINESS_GROUP_ID =
                          apps.fnd_profile.VALUE ('PER_BUSINESS_GROUP_ID')
                    AND PPA.ELEMENT_SET_ID = PES.ELEMENT_SET_ID          --EFE
                    AND PES.element_set_id = PESTL.element_set_id
                    AND PESTL.language = USERENV ('LANG')                --EFE
         GROUP BY   pay.payroll_id,
                    pay.PAYROLL_NAME,
                    ppe.person_id,
                    ppe.EMPLOYEE_NUMBER,
                    ppe.FULL_NAME,
                    ptp.time_period_id,
                    ptp.PERIOD_NAME,
                    ppe.PER_INFORMATION2,
                    ppe.PER_INFORMATION3,
                    ppe.NATIONAL_IDENTIFIER,
                    aou.NAME,
                    ppd.SEGMENT3,
                    hoi.ORG_INFORMATION1,
                    hoi.ORG_INFORMATION2,
                    pas.PAY_BASIS_ID,
                    pas.GRADE_ID,
                    pas.GRADE_ID,
                    pas.Assignment_id,
                    ptp.START_DATE,
                    ptp.CUT_OFF_DATE,
                    ppa.ELEMENT_SET_ID,
                    paa.ASSIGNMENT_ACTION_ID,
                    hlo.location_code,
                    paa.payroll_action_id,
                    ptp.period_num,
                    ppg.SEGMENT1,
                    pca.segment6,
                    pca.segment7,
                    PAS.SOFT_CODING_KEYFLEX_ID,
                    --efe
                    PESTL.element_set_name,
                    PRV.RESULT_VALUE,
                    prr.RUN_RESULT_ID
         --EFE
         ORDER BY   pay.PAYROLL_NAME,
                    ptp.time_period_id,
                    hlo.location_code,
                    ppe.FULL_NAME,
                    ppe.EMPLOYEE_NUMBER;          