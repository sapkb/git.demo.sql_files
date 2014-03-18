CREATE OR REPLACE PACKAGE BODY APPS.XXOEM_RECIBOS_ELECTRONICOS_PKG
AS
   /*******************************************

   --  Package specifications for developed programs
   --  to load legacy employees information through APIs
   --
   --  Type          Date          User
   --  Creation      08/01/2014    ERIK FERNANDO ESPINDOLA.
   --                              ERPSOL.

   ******************************************
   */
   
--genera la salida en output de aplicacion  
 PROCEDURE IMP_O(P_DATA IN VARCHAR2)
IS
BEGIN
  fnd_file.put_line (fnd_file.OUTPUT, P_DATA);
 DBMS_OUTPUT.PUT_LINE(P_DATA);
END;

---genera salida en registro de aplicacion
PROCEDURE IMP_L(P_DATA IN VARCHAR2)
IS
BEGIN
 fnd_file.put_line (fnd_file.LOG, P_DATA);
 DBMS_OUTPUT.PUT_LINE('LOG: '||P_DATA);
END;

--genara formato xml
FUNCTION G_XML(P_ETIQUETA IN VARCHAR2,P_DATA IN VARCHAR2) RETURN VARCHAR2
IS
BEGIN
 RETURN '     <'||P_ETIQUETA||'>'||P_DATA||'</'||P_ETIQUETA||'>';
END;
   PROCEDURE completa_saldos (p_recibo_id NUMBER, p_indice_sdo NUMBER)
   IS
      l_indice   NUMBER;
   BEGIN
      l_indice := p_indice_sdo;

      IF l_indice < 10
      THEN
         LOOP
            l_indice := l_indice + 1;

            INSERT INTO xxoem.XXOEM_PAY_RECIBO_SALDOS (RECIBO_ID,
                                                       NUM_LINEA,
                                                       CONCEPTO,
                                                       SALDO)
              VALUES   (p_recibo_id,
                        l_indice,
                        '',
                        '');

            EXIT WHEN l_indice >= 10;
         END LOOP;
      END IF;
   END;


   PROCEDURE completa_percepciones (p_recibo_id NUMBER, p_indice NUMBER)
   IS
      l_indice   NUMBER;
   BEGIN
      l_indice := p_indice;

      IF l_indice < 10
      THEN
         LOOP
            l_indice := l_indice + 1;

            INSERT INTO xxoem.XXOEM_PAY_RECIBO_PERCEPCIONES (
                                                                RECIBO_ID,
                                                                NUM_LINEA,
                                                                CONCEPTO,
                                                                IMPORTE,
                                                                IMPORTE_PERCEPCIONES,
                                                                ELEMENT_TYPE_ID,
                                                                DIAS
                       )
              VALUES   (p_recibo_id,
                        l_indice,
                        '',
                        '',
                        '',
                        1,
                        '');

            EXIT WHEN l_indice >= 10;
         END LOOP;
      END IF;
   END;


   PROCEDURE completa_deducciones (p_recibo_id NUMBER, p_indice NUMBER)
   IS
      l_indice   NUMBER;
   BEGIN
      l_indice := p_indice;

      IF l_indice < 11
      THEN
         LOOP
            l_indice := l_indice + 1;

            INSERT INTO xxoem.XXOEM_PAY_RECIBO_DEDUCCIONES (
                                                               RECIBO_ID,
                                                               NUM_LINEA,
                                                               CONCEPTO,
                                                               IMPORTE,
                                                               IMPORTE_DEDUCCIONES,
                                                               ELEMENT_TYPE_ID,
                                                               DIAS
                       )
              VALUES   (p_recibo_id,
                        l_indice,
                        '',
                        '',
                        '',
                        1,
                        '');

            EXIT WHEN l_indice >= 11;                                     --11
         END LOOP;
      END IF;
   END;


   PROCEDURE genera_recibos_electronicos (P_ERRORMSG     OUT VARCHAR2
                                          ,P_ERRORCODE    OUT NUMBER,
                                          P_PAYROLL_ACTION_ID    NUMBER,--
                                         -- P_ELEMENT_SET_ID       NUMBER,
                                          P_DIVISION             VARCHAR2,--
                                          P_CENTRO_COSTOS        VARCHAR2,--
                                          P_DEPARTAMENTO         VARCHAR2,--
                                          P_PERSON_ID            NUMBER--
                                         -- P_EMP_NUM_INI          VARCHAR2,
                                         -- P_EMP_NUM_FIN          VARCHAR2,
                                         -- P_LOCATION_CODE        VARCHAR2,
--                                          P_RECIBO_INI           NUMBER
                                          )
   IS
      
CURSOR c_empleados
IS
  SELECT   id_nomina,
           numero_empleado,
           fecha_pago,
           fecha_inicial,
           fecha_final,
           dias_pagados,
           salario_Base_Cot,
           SUM (SDI) SDI,
           time_period_id,
           person_id,
           payroll_action_id,
           decripcion,
           num_seg_social
    FROM   (  SELECT   DISTINCT
                       (ppe.EMPLOYEE_NUMBER) numero_empleado,
                       pay.payroll_id id_nomina,
                       SYSDATE fecha_pago,
                       ptp.START_DATE fecha_inicial,
                       ptp.CUT_OFF_DATE fecha_final,
                       (SELECT   pbvv2.VALUE
                          FROM   pay_balance_values_v pbvv2
                         WHERE   pbvv2.business_group_id =
                                    apps.fnd_profile.VALUE (
                                       'PER_BUSINESS_GROUP_ID'
                                    )
                                 AND (pbvv2.ASSIGNMENT_ACTION_ID =
                                         paa.ASSIGNMENT_ACTION_ID   -- 3743833
                                                                 )
                                 AND (pbvv2.DEFINED_BALANCE_ID =
                                         APPS.XXOEM_RECIBOS_ELECTRONICOS_PKG.P_DEFINED_BALANCE_ID(paa.ASSIGNMENT_ACTION_ID) --21724
                                                                                                                           ))
                          dias_pagados,
                       (select SUM (TO_NUMBER (prv2.result_value)) neto_total
                        from pay_run_results prr2,
                       pay_run_result_values prv2,
                       pay_element_types_f_tl petl2,
                       pay_element_types_f pet2
                        where 1=1
   ---------------------------------------------------------
                       and (pet2.element_name = 'I9999 NETO')
                       AND pet2.ELEMENT_TYPE_ID = petl2.ELEMENT_TYPE_ID
                       AND petl2.language =userenv('LANG')
                       and pet2.ELEMENT_TYPE_ID=prr2.ELEMENT_TYPE_ID
                       and prv2.RUN_RESULT_ID=prr2.RUN_RESULT_ID
                       and prr2.assignment_action_id=paa.assignment_action_id) salario_Base_Cot,
                       SUM(APPS.XXOEM_RECIBOS_ELECTRONICOS_PKG.F_REGRESA_SDI (
                              piv.INPUT_VALUE_ID,
                              prv.RUN_RESULT_ID
                           ))
                          SDI,
                       NVL (
                          (SELECT   PESTL.element_set_name
                             FROM   --pay_payroll_actions ppa
                                    pay_element_sets PES,
                                    pay_element_sets_tl PESTL
                            WHERE       1 = 1
                                    AND PPA.ELEMENT_SET_ID = PES.ELEMENT_SET_ID
                                    AND PES.element_set_id = PESTL.element_set_id
                                    AND PESTL.language = USERENV ('LANG')),
                          'NA'
                       )
                          decripcion,
                       ptp.time_period_id,
                       ppe.person_id,                                  
                       paa.payroll_action_id                          
                       ,hoi2.ORG_INFORMATION1 num_seg_social,----
                        ppe.FULL_NAME
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
                       pay_cost_allocation_keyflex pca
                       ----------------------------------
                       ,hr_organization_information hoi2
                WHERE       1 = 1
                AND hoi2.organization_id = sck.segment1
                       --and hoi2.organization_id=organization_id
                       AND hoi2.org_information_context = 'MX_SOC_SEC_DETAILS'
                       AND prr.RUN_RESULT_ID = prv.RUN_RESULT_ID
                       AND prr.ELEMENT_TYPE_ID = pet.ELEMENT_TYPE_ID
                       AND pjb.POSITION_DEFINITION_ID =
                             ppd.POSITION_DEFINITION_ID
                       AND prr.ASSIGNMENT_ACTION_ID = paa.ASSIGNMENT_ACTION_ID
                       AND ppa.PAYROLL_ACTION_ID = paa.PAYROLL_ACTION_ID
                       AND pas.location_id = hlo.location_id
                       AND ppa.BUSINESS_GROUP_ID = pgh.BUSINESS_GROUP_ID
                       AND paa.ASSIGNMENT_ID = pas.ASSIGNMENT_ID
                       AND pas.PEOPLE_GROUP_ID = ppg.PEOPLE_GROUP_ID    ---add
                       AND ppa.TIME_PERIOD_ID = ptp.TIME_PERIOD_ID
                       AND ppa.PAYROLL_ID = pay.PAYROLL_ID
                       AND pas.PERSON_ID = ppe.PERSON_ID
                       AND prv.INPUT_VALUE_ID = piv.INPUT_VALUE_ID
                       AND piv.name IN ('Pay Value', 'ISR Subject', 'ISR Exempt')
                       AND prv.result_value > '0'
                       AND PAS.SOFT_CODING_KEYFLEX_ID =
                             SCK.SOFT_CODING_KEYFLEX_ID
                       AND PAS.ORGANIZATION_ID = AOU.ORGANIZATION_ID
                       AND aou.COST_ALLOCATION_KEYFLEX_ID =
                             pca.COST_ALLOCATION_KEYFLEX_ID
                       AND PAS.POSITION_ID = PJB.POSITION_ID(+)
                       AND pgn.ENTITY_ID(+) = SCK.SEGMENT1
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
                       AND paa.payroll_action_id = P_PAYROLL_ACTION_ID
                       AND (ppg.SEGMENT1 = P_DIVISION OR P_DIVISION IS NULL)
                       AND (pca.segment6 = P_CENTRO_COSTOS
                            OR P_CENTRO_COSTOS IS NULL)
                       AND (pca.segment7 = P_DEPARTAMENTO
                            OR P_DEPARTAMENTO IS NULL)
                       AND (ppe.person_id = P_PERSON_ID OR P_PERSON_ID IS NULL)
                       AND pgh.BUSINESS_GROUP_ID =
                             apps.fnd_profile.VALUE ('PER_BUSINESS_GROUP_ID')
            --  AND ppe.EMPLOYEE_NUMBER = 5278 --5318--incapacidad por enfermedad --5278 incapacidad por maternidad 5278
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
                      -- piv.INPUT_VALUE_ID,
                      -- prv.RUN_RESULT_ID
                       hoi2.ORG_INFORMATION1)
GROUP BY   id_nomina,
           numero_empleado,
           fecha_pago,
           fecha_inicial,
           fecha_final,
           dias_pagados,
           salario_Base_Cot,
           time_period_id,
           person_id,
           payroll_action_id,
           decripcion
           ,num_seg_social
ORDER BY   numero_empleado;
 
 /*
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
                    0 salario_Base_Cot,
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
                    pay_cost_allocation_keyflex pca
                    ,pay_element_sets PES,
                    pay_element_sets_tl PESTL,                          ---EFE
                    PAY_ELEMENT_TYPES_F ETY,                             --efe
                    PAY_ELEMENT_TYPES_F_TL ETYTL                         --efe
            WHERE       1 = 1
                    AND ETY.element_type_id = ETYTL.element_type_id      --efe
                    AND ETYTL.LANGUAGE = USERENV ('LANG')                --efe
                    AND PIV.ELEMENT_TYPE_ID = ETY.ELEMENT_TYPE_ID        --efe
              --      AND PRR.ELEMENT_TYPE_ID = ETY.ELEMENT_TYPE_ID        --efe
                    AND (ETYTL.ELEMENT_NAME = 'I7001 SDI' or ETYTL.ELEMENT_NAME = null)
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
                    AND paa.payroll_action_id = P_PAYROLL_ACTION_ID
                    ------AND (ppa.ELEMENT_SET_ID = P_ELEMENT_SET_ID  OR P_ELEMENT_SET_ID IS NULL)
                    AND (ppg.SEGMENT1 = P_DIVISION OR P_DIVISION IS NULL)
                  AND (pca.segment6 = P_CENTRO_COSTOS
                         OR P_CENTRO_COSTOS IS NULL)
                    AND (pca.segment7 = P_DEPARTAMENTO
                         OR P_DEPARTAMENTO IS NULL)
                    AND (ppe.person_id = P_PERSON_ID OR P_PERSON_ID IS NULL)
                    ---AND ppe.EMPLOYEE_NUMBER >= NVL (P_EMP_NUM_INI, ppe.EMPLOYEE_NUMBER) AND ppe.EMPLOYEE_NUMBER <= NVL (P_EMP_NUM_FIN, ppe.EMPLOYEE_NUMBER)
                    --AND hlo.location_code = NVL (P_LOCATION_CODE, hlo.location_code)                  
                    AND pgh.BUSINESS_GROUP_ID = apps.fnd_profile.VALUE ('PER_BUSINESS_GROUP_ID')
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
                    PAS.SOFT_CODING_KEYFLEX_ID
                    --efe
                    ,PESTL.element_set_name,
                    PRV.RESULT_VALUE,
                    prr.RUN_RESULT_ID
         --EFE
         ORDER BY   pay.PAYROLL_NAME,
                    ptp.time_period_id,
                    hlo.location_code,
                    ppe.FULL_NAME,
                    ppe.EMPLOYEE_NUMBER;
                    
*/
/*
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
                    0 salario_Base_Cot,
--                    PRV.RESULT_VALUE SDI,
  --                  PESTL.element_set_name decripcion,
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
                    pay_cost_allocation_keyflex pca
--                    pay_element_sets PES,
--                    pay_element_sets_tl PESTL,                          ---EFE
--                    PAY_ELEMENT_TYPES_F ETY,                             --efe
--                    PAY_ELEMENT_TYPES_F_TL ETYTL                         --efe
            WHERE       1 = 1
--                    AND ETY.element_type_id = ETYTL.element_type_id      --efe
--                    AND ETYTL.LANGUAGE = USERENV ('LANG')                --efe
--                    AND PIV.ELEMENT_TYPE_ID = ETY.ELEMENT_TYPE_ID        --efe
--                    AND PRR.ELEMENT_TYPE_ID = ETY.ELEMENT_TYPE_ID        --efe
--                    AND ETYTL.ELEMENT_NAME = 'I7001 SDI'
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
                    AND paa.payroll_action_id = P_PAYROLL_ACTION_ID
                    ------AND (ppa.ELEMENT_SET_ID = P_ELEMENT_SET_ID  OR P_ELEMENT_SET_ID IS NULL)
                    AND (ppg.SEGMENT1 = P_DIVISION OR P_DIVISION IS NULL)
                  AND (pca.segment6 = P_CENTRO_COSTOS
                         OR P_CENTRO_COSTOS IS NULL)
                    AND (pca.segment7 = P_DEPARTAMENTO
                         OR P_DEPARTAMENTO IS NULL)
                    AND (ppe.person_id = P_PERSON_ID OR P_PERSON_ID IS NULL)
                    ---AND ppe.EMPLOYEE_NUMBER >= NVL (P_EMP_NUM_INI, ppe.EMPLOYEE_NUMBER) AND ppe.EMPLOYEE_NUMBER <= NVL (P_EMP_NUM_FIN, ppe.EMPLOYEE_NUMBER)
                    --AND hlo.location_code = NVL (P_LOCATION_CODE, hlo.location_code)                  
                    AND pgh.BUSINESS_GROUP_ID = apps.fnd_profile.VALUE ('PER_BUSINESS_GROUP_ID')
--                    AND PPA.ELEMENT_SET_ID = PES.ELEMENT_SET_ID          --EFE
--                    AND PES.element_set_id = PESTL.element_set_id
--                    AND PESTL.language = USERENV ('LANG')                --EFE
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
                    PAS.SOFT_CODING_KEYFLEX_ID
                    --efe
--                    PESTL.element_set_name,
--                    PRV.RESULT_VALUE,
--                    prr.RUN_RESULT_ID
         --EFE
         ORDER BY   pay.PAYROLL_NAME,
                    ptp.time_period_id,
                    hlo.location_code,
                    ppe.FULL_NAME,
                    ppe.EMPLOYEE_NUMBER;
*/




--      CURSOR c_saldos (
--         p_PAYROLL_ACTION_ID                 NUMBER,
--         p_person_id                         NUMBER,
--         p_time_period_id                    NUMBER
--      )
--      IS
-- SELECT   pay.payroll_id,
--                    ptp.time_period_id,
--                    ppe.person_id,
--                    UPPER (pet.reporting_name) CONCEPTO,
--                    ptp.REGULAR_PAYMENT_DATE,
--                    prv.result_value SALDO
--             FROM   pay_run_results prr,
--                    pay_run_result_values prv,
--                    pay_element_types_f pet,
--                    pay_assignment_actions paa,
--                    pay_payroll_actions ppa,
--                    per_time_periods ptp,
--                    per_all_assignments_f pas,
--                    per_all_people_f ppe                                 ---ok
--                                        ,
--                    pay_all_payrolls_f pay                               ---ok
--                                          ,
--                    pay_input_values_f piv
--            WHERE       1 = 1
--                    AND prr.RUN_RESULT_ID = prv.RUN_RESULT_ID
--                    AND prr.ELEMENT_TYPE_ID = pet.ELEMENT_TYPE_ID
--                    AND prr.ASSIGNMENT_ACTION_ID = paa.ASSIGNMENT_ACTION_ID
--                    AND ppa.PAYROLL_ACTION_ID = paa.PAYROLL_ACTION_ID
--                    AND prv.INPUT_VALUE_ID = piv.INPUT_VALUE_ID
--                    AND piv.name IN ('Saldo')
--                    AND prv.result_value IS NOT NULL
--                    AND prv.result_value <> '0'
--                    AND paa.ASSIGNMENT_ID = pas.ASSIGNMENT_ID
--                    AND ppa.TIME_PERIOD_ID = ptp.TIME_PERIOD_ID
--                    AND ppa.PAYROLL_ID = pay.PAYROLL_ID
--                    AND pas.PERSON_ID = ppe.PERSON_ID
--                    AND (ptp.REGULAR_PAYMENT_DATE >= pet.EFFECTIVE_START_DATE
--                         AND ptp.REGULAR_PAYMENT_DATE <= pet.EFFECTIVE_END_DATE)
--                    AND (ptp.REGULAR_PAYMENT_DATE >= pas.EFFECTIVE_START_DATE
--                         AND ptp.REGULAR_PAYMENT_DATE <= pas.EFFECTIVE_END_DATE)
--                    AND (ptp.REGULAR_PAYMENT_DATE >= ppe.EFFECTIVE_START_DATE
--                         AND ptp.REGULAR_PAYMENT_DATE <= ppe.EFFECTIVE_END_DATE)
--                    AND (ptp.REGULAR_PAYMENT_DATE >= pay.EFFECTIVE_START_DATE
--                         AND ptp.REGULAR_PAYMENT_DATE <= pay.EFFECTIVE_END_DATE)
--                    AND paa.payroll_action_id = p_PAYROLL_ACTION_ID
--                    AND ppe.person_id = p_PERSON_ID
--                    AND ptp.time_period_id = p_TIME_PERIOD_ID
--         GROUP BY   pay.payroll_id,
--                    ptp.time_period_id,
--                    ppe.person_id,
--                    UPPER (pet.reporting_name),
--                    ptp.REGULAR_PAYMENT_DATE,
--                    pet.element_type_id,
--                    prv.result_value;


      --- Cursor para PERCEPCIONES ----
 /*     CURSOR c_percepciones (
         P_ELEMENT_SET_ID                    NUMBER,
         p_PAYROLL_ACTION_ID                 NUMBER,
         p_person_id                         NUMBER,
         p_time_period_id                    NUMBER
      )
      IS
           SELECT   PAYROLL_ID,
                    TIME_PERIOD_ID,
                    PERSON_ID,
                    NUM_ELEM_DEDUC_ORD,
                    CONCEPTO,
                    REGULAR_PAYMENT_DATE,
                    IMPORTE,
                    IMPORTE_PERCEPCIONES,
                    ELEMENT_TYPE_ID,
                    DIAS
             FROM   (  SELECT   pay.payroll_id,
                                ptp.time_period_id,
                                ppe.person_id,
                                NVL (TO_NUMBER (pet.attribute1), 1000)
                                   num_elem_deduc_ord,
                                UPPER (petl.reporting_name) Concepto,
                                ptp.REGULAR_PAYMENT_DATE,
                                SUM (TO_NUMBER (prv.result_value)) importe,
                                SUM (TO_NUMBER (prv.result_value))
                                   importe_percepciones,
                                pet.element_type_id,
                                SUM( (SELECT   TO_NUMBER (prrd.result_value)
                                        FROM   pay_run_result_values prrd,
                                               pay_input_values_f pivd
                                       WHERE   prrd.run_result_id =
                                                  prr.run_result_id
                                               AND prrd.INPUT_VALUE_ID =
                                                     pivd.INPUT_VALUE_ID
                                               AND pivd.name IN
                                                        ('Days',
                                                         'Hours',
                                                         'Dias Trabajados')))
                                   dias
                         FROM   pay_run_results prr,
                                pay_run_result_values prv,
                                pay_element_types_f pet,
                                pay_element_types_f_tl petl,
                                pay_assignment_actions paa,
                                pay_payroll_actions ppa,
                                per_time_periods ptp,
                                per_all_assignments_f pas,
                                per_all_people_f ppe                     ---ok
                                                    ,
                                pay_all_payrolls_f pay                   ---ok
                                                      ,
                                pay_element_classifications pec          ---ok
                                                               --      ,PAY_ELEMENT_SETS_TL              pes
                                                               --      ,PAY_ELEMENT_TYPE_RULES           per
                                ,
                                pay_input_values_f piv
                        WHERE       1 = 1
                                AND prr.RUN_RESULT_ID = prv.RUN_RESULT_ID
                                AND prr.ELEMENT_TYPE_ID = pet.ELEMENT_TYPE_ID
                                AND pet.ELEMENT_TYPE_ID = petl.ELEMENT_TYPE_ID
                                AND petl.language = 'ESA'
                                AND prr.ASSIGNMENT_ACTION_ID =
                                      paa.ASSIGNMENT_ACTION_ID
                                AND ppa.PAYROLL_ACTION_ID = paa.PAYROLL_ACTION_ID
                                AND prv.INPUT_VALUE_ID = piv.INPUT_VALUE_ID
                                AND piv.name IN ('Pay Value') --- ('ISR Subject','ISR Exempt')
                                --and    ppa.BUSINESS_GROUP_ID             =             81
                                AND pet.CLASSIFICATION_ID = pec.CLASSIFICATION_ID
                                AND paa.ASSIGNMENT_ID = pas.ASSIGNMENT_ID
                                AND ppa.TIME_PERIOD_ID = ptp.TIME_PERIOD_ID
                                AND ppa.PAYROLL_ID = pay.PAYROLL_ID
                                AND pas.PERSON_ID = ppe.PERSON_ID
                                AND (ptp.REGULAR_PAYMENT_DATE >=
                                        pet.EFFECTIVE_START_DATE
                                     AND ptp.REGULAR_PAYMENT_DATE <=
                                           pet.EFFECTIVE_END_DATE)
                                AND (ptp.REGULAR_PAYMENT_DATE >=
                                        pas.EFFECTIVE_START_DATE
                                     AND ptp.REGULAR_PAYMENT_DATE <=
                                           pas.EFFECTIVE_END_DATE)
                                AND (ptp.REGULAR_PAYMENT_DATE >=
                                        ppe.EFFECTIVE_START_DATE
                                     AND ptp.REGULAR_PAYMENT_DATE <=
                                           ppe.EFFECTIVE_END_DATE)
                                AND (ptp.REGULAR_PAYMENT_DATE >=
                                        pay.EFFECTIVE_START_DATE
                                     AND ptp.REGULAR_PAYMENT_DATE <=
                                           pay.EFFECTIVE_END_DATE)
                                AND (pet.ELEMENT_TYPE_ID IN
                                           (SELECT   per.ELEMENT_TYPE_ID
                                              FROM   PAY_ELEMENT_TYPE_RULES per
                                             WHERE   per.ELEMENT_SET_ID =
                                                        P_ELEMENT_SET_ID
                                                     OR P_ELEMENT_SET_ID IS NULL))
                                AND (pet.ELEMENT_TYPE_ID IN
                                           (SELECT   per.ELEMENT_TYPE_ID
                                              FROM   PAY_ELEMENT_SETS_TL pes,
                                                     PAY_ELEMENT_TYPE_RULES per
                                             WHERE   pes.ELEMENT_SET_ID =
                                                        per.ELEMENT_SET_ID
                                                     AND pes.language = 'ESA'
                                                     AND pes.element_set_name IN
                                                              ('PERCEPCIONES_RECIBO')
                                                     AND per.include_or_exclude =
                                                           'I')
                                     OR (pet.CLASSIFICATION_ID IN
                                               (SELECT   per.CLASSIFICATION_ID
                                                  FROM   PAY_ELEMENT_SETS_TL pes,
                                                         PAY_ELE_CLASSIFICATION_RULES per
                                                 WHERE   pes.ELEMENT_SET_ID =
                                                            per.ELEMENT_SET_ID
                                                         AND pes.language = 'ESA'
                                                         AND pes.element_set_name IN
                                                                  ('PERCEPCIONES_RECIBO'))
                                         AND pet.ELEMENT_TYPE_ID NOT IN
                                                  (SELECT   per.ELEMENT_TYPE_ID
                                                     FROM   PAY_ELEMENT_SETS_TL pes,
                                                            PAY_ELEMENT_TYPE_RULES per
                                                    WHERE   pes.ELEMENT_SET_ID =
                                                               per.ELEMENT_SET_ID
                                                            AND pes.language =
                                                                  'ESA'
                                                            AND pes.element_set_name IN
                                                                     ('PERCEPCIONES_RECIBO')
                                                            AND per.include_or_exclude =
                                                                  'E')))
                                AND paa.payroll_action_id = P_PAYROLL_ACTION_ID
                                AND ppe.person_id = p_PERSON_ID
                                AND ptp.time_period_id = p_TIME_PERIOD_ID
                     GROUP BY   pay.payroll_id,
                                ptp.time_period_id,
                                ppe.person_id,
                                NVL (TO_NUMBER (pet.attribute1), 1000),
                                UPPER (petl.reporting_name),
                                ptp.REGULAR_PAYMENT_DATE,
                                pet.element_type_id)
            WHERE   importe_percepciones <> 0
         ORDER BY   4;
*/

CURSOR c_percepciones ( P_ELEMENT_SET_ID                    NUMBER,
         p_PAYROLL_ACTION_ID                 NUMBER,
         p_person_id                         NUMBER,
         p_time_period_id                    NUMBER
      )
      IS
 SELECT   PAYROLL_ID,
           RUN_RESULT_ID,
           TIME_PERIOD_ID,
           PERSON_ID,
           gravado,
           exento,
           NUM_ELEM_DEDUC_ORD,
--           substr(CONCEPTO,0,15) concepto,
           CONCEPTO,
           REGULAR_PAYMENT_DATE,
           IMPORTE,
           IMPORTE_PERCEPCIONES,
           ELEMENT_TYPE_ID,
           DIAS,
           TIPO_PERCEPCION,
           descripcion_percepcion
    FROM   (  SELECT   pay.payroll_id,
                       ptp.time_period_id,
                       ppe.person_id,
                       pRV.RUN_RESULT_ID                                 --efe
                       ,NVL(PET.ATTRIBUTE1,'') TIPO_PERCEPCION,
                       PET.ATTRIBUTE2 descripcion_percepcion,
                       NVL (
                          (SELECT   RRV.RESULT_VALUE
                             FROM   HR_LOOKUPS LO1,
                                    HR_LOOKUPS LO2,
                                    PAY_INPUT_VALUES_F INV,
                                    PAY_INPUT_VALUES_F_TL INVTL,
                                    PAY_RUN_RESULT_VALUES RRV
                            WHERE       INV.INPUT_VALUE_ID = INVTL.INPUT_VALUE_ID
                                    AND INVTL.LANGUAGE = USERENV ('LANG')
                                    AND RRV.INPUT_VALUE_ID = INV.INPUT_VALUE_ID
                                    --and RRV.INPUT_VALUE_ID in(1667,1666)
                                    --AND RRV.INPUT_VALUE_ID = 1666        --efe
                                    and invtl.name='ISR Subject'--efe
                                    AND LO1.LOOKUP_TYPE = 'YES_NO'
                                    AND LO1.LOOKUP_CODE =
                                          DECODE (INV.MANDATORY_FLAG,
                                                  'X', 'N',
                                                  INV.MANDATORY_FLAG)
                                    AND LO2.LOOKUP_TYPE = 'UNITS'
                                    AND LO2.LOOKUP_CODE = INV.UOM
                                    AND (RRV.RUN_RESULT_ID = pRV.RUN_RESULT_ID --13831862
                                         )), 0 )
                          gravado,
                       NVL (
                          (SELECT   RRV.RESULT_VALUE
                             FROM   HR_LOOKUPS LO1,
                                    HR_LOOKUPS LO2,
                                    PAY_INPUT_VALUES_F INV,
                                    PAY_INPUT_VALUES_F_TL INVTL,
                                    PAY_RUN_RESULT_VALUES RRV
                            WHERE       INV.INPUT_VALUE_ID = INVTL.INPUT_VALUE_ID
                                    AND INVTL.LANGUAGE = USERENV ('LANG')
                                    AND RRV.INPUT_VALUE_ID = INV.INPUT_VALUE_ID /* DECODE NON-USER ENTERABLE TO NOT MANDATORY */
                                    --and RRV.INPUT_VALUE_ID in(1667,1666)
                                    and invtl.name='ISR Exempt'--efe
                                    --AND RRV.INPUT_VALUE_ID = 1667        --efe
                                    AND LO1.LOOKUP_TYPE = 'YES_NO'
                                    AND LO1.LOOKUP_CODE =
                                          DECODE (INV.MANDATORY_FLAG,
                                                  'X', 'N',
                                                  INV.MANDATORY_FLAG)
                                    AND LO2.LOOKUP_TYPE = 'UNITS'
                                    AND LO2.LOOKUP_CODE = INV.UOM
                                    AND (RRV.RUN_RESULT_ID = pRV.RUN_RESULT_ID --13831862
                                         )),0)
                          exento,
                       NVL (TO_NUMBER (pet.attribute1), 1000) num_elem_deduc_ord,
                       UPPER (petl.reporting_name) Concepto,
                       ptp.REGULAR_PAYMENT_DATE,
                      sum(to_number(prv.result_value))over (partition by petl.reporting_name) over_by,
                       SUM (TO_NUMBER (prv.result_value)) importe,
                       SUM (TO_NUMBER (prv.result_value)) importe_percepciones,
                       pet.element_type_id,
                       SUM( (SELECT   TO_NUMBER (prrd.result_value)
                               FROM   pay_run_result_values prrd,
                                      pay_input_values_f pivd
                              WHERE   prrd.run_result_id = prr.run_result_id
                                      AND prrd.INPUT_VALUE_ID =
                                            pivd.INPUT_VALUE_ID
                                      AND pivd.name IN
                                               ('Days',
                                                'Hours',
                                                'Dias Trabajados')))
                          dias
               --           pet.*
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
--               and PET.ATTRIBUTE2 not in('Horas extra')
                       AND prr.RUN_RESULT_ID = prv.RUN_RESULT_ID
                       AND prr.ELEMENT_TYPE_ID = pet.ELEMENT_TYPE_ID
                       AND pet.ELEMENT_TYPE_ID = petl.ELEMENT_TYPE_ID
                       AND petl.language = 'ESA'
                       AND prr.ASSIGNMENT_ACTION_ID = paa.ASSIGNMENT_ACTION_ID
                       AND ppa.PAYROLL_ACTION_ID = paa.PAYROLL_ACTION_ID
                       AND prv.INPUT_VALUE_ID = piv.INPUT_VALUE_ID
                       AND piv.name IN ('Pay Value') --- ('ISR Subject','ISR Exempt')
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
                       AND (pet.ELEMENT_TYPE_ID IN
                                  (SELECT   per.ELEMENT_TYPE_ID
                                     FROM   PAY_ELEMENT_TYPE_RULES per
                                    WHERE   per.ELEMENT_SET_ID =
                                               P_ELEMENT_SET_ID
                                            OR P_ELEMENT_SET_ID IS NULL))
                       AND (pet.ELEMENT_TYPE_ID IN
                                  (SELECT   per.ELEMENT_TYPE_ID
                                     FROM   PAY_ELEMENT_SETS_TL pes,
                                            PAY_ELEMENT_TYPE_RULES per
                                    WHERE   pes.ELEMENT_SET_ID =
                                               per.ELEMENT_SET_ID
                                            AND pes.language = 'ESA'
                                            AND pes.element_set_name IN
                                                  ('Percepciones SAT')--     ('PERCEPCIONES_RECIBO')
                                            AND per.include_or_exclude = 'I')
                            OR (pet.CLASSIFICATION_ID IN
                                      (SELECT   per.CLASSIFICATION_ID
                                         FROM   PAY_ELEMENT_SETS_TL pes,
                                                PAY_ELE_CLASSIFICATION_RULES per
                                        WHERE   pes.ELEMENT_SET_ID =
                                                   per.ELEMENT_SET_ID
                                                AND pes.language = 'ESA'
                                                AND pes.element_set_name IN
                                                 ('Percepciones SAT'))--          ('PERCEPCIONES_RECIBO'))
                                AND pet.ELEMENT_TYPE_ID NOT IN
                                         (SELECT   per.ELEMENT_TYPE_ID
                                            FROM   PAY_ELEMENT_SETS_TL pes,
                                                   PAY_ELEMENT_TYPE_RULES per
                                           WHERE   pes.ELEMENT_SET_ID =
                                                      per.ELEMENT_SET_ID
                                                   AND pes.language = 'ESA'
                                                   AND pes.element_set_name IN
                                                   ('Percepciones SAT')--           ('PERCEPCIONES_RECIBO')
                                                   AND per.include_or_exclude =
                                                         'E')))
                       AND paa.payroll_action_id = P_PAYROLL_ACTION_ID --162847
                       AND ppe.person_id = p_PERSON_ID                --11069
                       AND ptp.time_period_id = p_TIME_PERIOD_ID       --5698
            GROUP BY   pay.payroll_id,
                       ptp.time_period_id,
                       ppe.person_id,
                       NVL (TO_NUMBER (pet.attribute1), 1000),
                       UPPER (petl.reporting_name),
                       ptp.REGULAR_PAYMENT_DATE,
                       pet.element_type_id,
                       pRV.RUN_RESULT_ID                                 --efe
                        ,PET.ATTRIBUTE1
                       ,PET.ATTRIBUTE2,prv.result_value,petl.reporting_name
                                        )
   WHERE   importe_percepciones <> 0
ORDER BY   4;


      --- Cursor para DEDUCCIONES ----
      CURSOR c_deducciones (
         P_ELEMENT_SET_ID                    NUMBER,
         p_PAYROLL_ACTION_ID                 NUMBER,
         p_person_id                         NUMBER,
         p_time_period_id                    NUMBER
      )
      IS
select --substr(prueba.concepto,0,15) concepto,
            prueba.concepto,
            prueba.over_by,
            nvl(prueba.dias,0)dias,
            prueba.gravado,
            prueba.exento,
            prueba.element_type_id,
--prueba.importe_deducciones,prueba.importe,
            PRUEBA.TIPO_DEDUCCION ,
            PRUEBA.descripcion_DEDUCCION--,run_result_id
FROM  
       (
        Select --distinct (sum(prv.result_value) over (partition by petl.reporting_name)) over_by,pay.payroll_id, 
                  ptp.time_period_id 
                  ,ppe.person_id
                  ,decode(upper(petl.reporting_name),'CÁLCULO DE CUOTA DE SEGURIDAD SOCIAL EE','3100 DESCUENTO CUOTA OBRERA IMSS',
                                                     'CÁLCULO DE CUOTA DE SEGURO SOCIAL EE'   ,'3100 DESCUENTO CUOTA OBRERA IMSS' ,upper(petl.reporting_name)) Concepto
        ,sum(to_number(prv.result_value))over (partition by petl.reporting_name) over_by                                                     
                  ,ptp.REGULAR_PAYMENT_DATE
                  --,prr.run_result_id
        --         ,to_number(prv.result_value)      importe
          --        ,to_number(prv.result_value)     importe_deducciones
                  ,pet.element_type_id
                  ,nvl(PET.ATTRIBUTE1,'NA') TIPO_DEDUCCION
                  ,nvl(PET.ATTRIBUTE2,'NA') descripcion_DEDUCCION
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
                     where   per.ELEMENT_SET_ID                =     P_ELEMENT_SET_ID      
                     or      P_ELEMENT_SET_ID is null      
                    )
                  )  
            and  (
                 pet.ELEMENT_TYPE_ID             in
                   ( Select  per.ELEMENT_TYPE_ID 
                     from    PAY_ELEMENT_SETS_TL              pes
                            ,PAY_ELEMENT_TYPE_RULES           per
                     where   pes.ELEMENT_SET_ID                =             per.ELEMENT_SET_ID    
                       and   pes.language                      =             'ESA'
                       and   pes.element_set_name             in            ('Deducciones SAT') -- ('DEDUCCIONES_RECIBO' )
                       and   per.include_or_exclude            =              'I'
                    )    
                 or (  pet.CLASSIFICATION_ID              in 
                           (Select  per.CLASSIFICATION_ID
                             from    PAY_ELEMENT_SETS_TL              pes
                                    ,PAY_ELE_CLASSIFICATION_RULES     per
                             where   pes.ELEMENT_SET_ID                =             per.ELEMENT_SET_ID    
                               and   pes.language                      =             'ESA'
                               and   pes.element_set_name             in             ('Deducciones SAT')-- ('DEDUCCIONES_RECIBO')
                            ) 
                          and pet.ELEMENT_TYPE_ID        not      in
                           ( Select  per.ELEMENT_TYPE_ID 
                             from    PAY_ELEMENT_SETS_TL              pes
                                    ,PAY_ELEMENT_TYPE_RULES           per
                             where   pes.ELEMENT_SET_ID                =             per.ELEMENT_SET_ID    
                               and   pes.language                      =             'ESA'
                               and   pes.element_set_name             in             ('Deducciones SAT')--  ('DEDUCCIONES_RECIBO')
                               and   per.include_or_exclude            =              'E'
                            ) 
                       )
                   )  
            and    paa.payroll_action_id                           = P_PAYROLL_ACTION_ID    
            and    ppe.person_id                          = p_PERSON_ID
            and    ptp.time_period_id     = p_TIME_PERIOD_ID
/*Union all
            Select
            ptp.time_period_id 
                  ,ppe.person_id
                  ,upper(petl.reporting_name) Concepto,
 sum(to_number(prv.result_value))over (partition by petl.reporting_name) over_by
                  ,ptp.REGULAR_PAYMENT_DATE
                  ,pet.element_type_id
                  ,PET.ATTRIBUTE1 TIPO_DEDUCCION
                  ,PET.ATTRIBUTE2 descripcion_DEDUCCION
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
            AND RRV.INPUT_VALUE_ID = INV.INPUT_VALUE_ID 
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
            AND RRV.INPUT_VALUE_ID = INV.INPUT_VALUE_ID 
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
                     where   per.ELEMENT_SET_ID                =     P_ELEMENT_SET_ID      
                     or      P_ELEMENT_SET_ID is null      
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
            and    paa.payroll_action_id                           = P_PAYROLL_ACTION_ID    
            and    ppe.person_id                          = p_PERSON_ID
            and    ptp.time_period_id     = p_TIME_PERIOD_ID*/
) prueba
group by prueba.concepto,prueba.over_by,prueba.dias,prueba.gravado,prueba.exento
,prueba.element_type_id,PRUEBA.TIPO_DEDUCCION ,PRUEBA.descripcion_DEDUCCION;


------------------------cursor incaPacidades ---

CURSOR c_incapacidades (
         --P_ELEMENT_SET_ID                    NUMBER,
         p_PAYROLL_ACTION_ID                 NUMBER,
         p_person_id                         NUMBER,
         p_time_period_id                    NUMBER
      )
      IS
SELECT DISTINCT(CONCEPTO) concepto, 
SUM(IMPORTE) importe , 
SUM(DIAS) dias ,
element_type_id
FROM (
SELECT   
pay.payroll_id,
                       ptp.time_period_id,
                       ppe.person_id,
                       pet.attribute2 Concepto,
                       --UPPER (petl.reporting_name) Concepto,--
                       SUM (TO_NUMBER (prv.result_value)) importe,
                       SUM( (SELECT   TO_NUMBER (prrd.result_value)
                               FROM   pay_run_result_values prrd,
                                      pay_input_values_f pivd
                              WHERE   prrd.run_result_id = prr.run_result_id
                                      AND prrd.INPUT_VALUE_ID =
                                            pivd.INPUT_VALUE_ID
                                      AND pivd.name IN
                                               ('Days',
                                                'Hours',
                                                'Dias Trabajados')))
                         dias,
                         pet.element_type_id
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
                       and piv.name='Pay Value'
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
--                       AND  pet.element_name like 'I5015 HORAS EXTRAS'
                         --and petl.element_type_id=446
                       AND paa.payroll_action_id = P_PAYROLL_ACTION_ID --162847
                       AND ppe.person_id = p_PERSON_ID                --11069
                       AND ptp.time_period_id = p_TIME_PERIOD_ID       --5698
                                          and  (pet.ELEMENT_TYPE_ID             in
                   ( Select  per.ELEMENT_TYPE_ID 
                     from    PAY_ELEMENT_SETS_TL              pes
                            ,PAY_ELEMENT_TYPE_RULES           per
                     where   pes.ELEMENT_SET_ID                =             per.ELEMENT_SET_ID    
                       and   pes.language                      =            USERENV('LANG')
                       and   pes.element_set_name             in             ('Incapacidad SAT')-- ('DEDUCCIONES_RECIBO' )
                       and   per.include_or_exclude            =              'I'
                    )    
                 or (  pet.CLASSIFICATION_ID              in 
                           (Select  per.CLASSIFICATION_ID
                             from    PAY_ELEMENT_SETS_TL              pes
                                    ,PAY_ELE_CLASSIFICATION_RULES     per
                             where   pes.ELEMENT_SET_ID                =             per.ELEMENT_SET_ID    
                               and   pes.language                      =            USERENV('LANG')
                               and   pes.element_set_name             in     ('Incapacidad SAT') --        ('DEDUCCIONES_RECIBO')
                            ) 
                          and pet.ELEMENT_TYPE_ID        not      in
                           ( Select  per.ELEMENT_TYPE_ID 
                             from    PAY_ELEMENT_SETS_TL              pes
                                    ,PAY_ELEMENT_TYPE_RULES           per
                             where   pes.ELEMENT_SET_ID                =             per.ELEMENT_SET_ID    
                               and   pes.language                      =            USERENV('LANG')
                               and   pes.element_set_name             in             ('Incapacidad SAT')  --('DEDUCCIONES_RECIBO')
                               and   per.include_or_exclude            =              'E'
                            ) 
                       )
                   )
                        GROUP BY   pay.payroll_id,
                       ptp.time_period_id,
                       ppe.person_id,
                       NVL (TO_NUMBER (pet.attribute1), 1000),
                       UPPER (petl.reporting_name),
                       ptp.REGULAR_PAYMENT_DATE,
                       pet.element_type_id,
                       pRV.RUN_RESULT_ID,pet.attribute2
)
GROUP BY CONCEPTO,element_type_id;                       
                      

------------------------CURSOR HORAS EXTRAS---------------
CURSOR c_H_EXTRAS (
        -- P_ELEMENT_SET_ID                    NUMBER,
         p_PAYROLL_ACTION_ID                 NUMBER,
         p_person_id                         NUMBER,
         p_time_period_id                    NUMBER
      )
      IS
  SELECT   pet.element_type_id element_type_id
  ,prv.result_value importe_pagado,---- horas extras, 
                       pay.payroll_id payroll_id,
                       ptp.time_period_id time_period_id,
                       ppe.person_id person_id,
                       UPPER (petl.reporting_name) Concepto,-- tipo incapacidad
                      -- SUM (TO_NUMBER (prv.result_value)) importe,--importe incapacidad
                       SUM( (SELECT   TO_NUMBER (prrd.result_value)
                               FROM   pay_run_result_values prrd,
                                      pay_input_values_f pivd
                              WHERE   prrd.run_result_id = prr.run_result_id
                                      AND prrd.INPUT_VALUE_ID =
                                            pivd.INPUT_VALUE_ID
                                      AND pivd.name IN
                                               ('Hours'))) horas_extras
                    , SUM( (SELECT   TO_NUMBER (prrd.result_value)
                               FROM   pay_run_result_values prrd,
                                      pay_input_values_f pivd
                              WHERE   prrd.run_result_id = prr.run_result_id
                                      AND prrd.INPUT_VALUE_ID =
                                            pivd.INPUT_VALUE_ID
                                      AND pivd.name IN
                                               ('Dias'
                                                ))) Dias
                 --dias incapacidad(1 hora=1 dia, entre 1 y 2 horas=2 dias, mas de 2 horas=3 dias)  
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
                       AND paa.payroll_action_id = P_PAYROLL_ACTION_ID --162847
                       AND ppe.person_id = p_PERSON_ID                --11069
                      AND ptp.time_period_id = p_TIME_PERIOD_ID       --5698
                      and piv.name='Pay Value'--
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
               ORDER BY petl.element_name;
                        
               --VARIABLES EFE
TIPO_HORAS VARCHAR2(10);
DIAS_EXTRA NUMBER;
P_RECIBO_INI NUMBER:=1;
descripcion_per varchar(100);
descripcion_ded varchar(100);
TIPO_per varchar(10);
TIPO_ded varchar(10);
valor_exento number;
/*         SELECT   pay.payroll_id,
                  ptp.time_period_id,
                  ppe.person_id,
                  DECODE (UPPER (petl.reporting_name),
                          'CÁLCULO DE CUOTA DE SEGURIDAD SOCIAL EE',
                          '3100 DESCUENTO CUOTA OBRERA IMSS',
                          'CÁLCULO DE CUOTA DE SEGURO SOCIAL EE',
                          '3100 DESCUENTO CUOTA OBRERA IMSS',
                          UPPER (petl.reporting_name))
                     Concepto,
                  ptp.REGULAR_PAYMENT_DATE,
                  TO_NUMBER (prv.result_value) importe,
                  TO_NUMBER (prv.result_value) importe_deducciones,
                  pet.element_type_id,
                  (SELECT   TO_NUMBER (prrd.result_value)
                     FROM   pay_run_result_values prrd,
                            pay_input_values_f pivd
                    WHERE   prrd.run_result_id = prr.run_result_id
                            AND prrd.INPUT_VALUE_ID = pivd.INPUT_VALUE_ID
                            AND pivd.name IN
                                     ('Days', 'Hours', 'Dias Trabajados'))
                     dias
           FROM   pay_run_results prr,
                  pay_run_result_values prv,
                  pay_element_types_f pet,
                  pay_element_types_f_tl petl,
                  pay_assignment_actions paa,
                  pay_payroll_actions ppa,
                  per_time_periods ptp,
                  per_all_assignments_f pas,
                  per_all_people_f ppe                                   ---ok
                                      ,
                  pay_all_payrolls_f pay                                 ---ok
                                        ,
                  pay_element_classifications pec                        ---ok
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
                  AND prv.result_value <> '0'
                  AND piv.name IN ('Pay Value') ---      ('ISR Subject','ISR Exempt')
                  --and    ppa.BUSINESS_GROUP_ID             =             81
                  AND pet.CLASSIFICATION_ID = pec.CLASSIFICATION_ID
                  AND paa.ASSIGNMENT_ID = pas.ASSIGNMENT_ID
                  AND ppa.TIME_PERIOD_ID = ptp.TIME_PERIOD_ID
                  AND ppa.PAYROLL_ID = pay.PAYROLL_ID
                  AND pas.PERSON_ID = ppe.PERSON_ID
                  AND (ptp.REGULAR_PAYMENT_DATE >= pet.EFFECTIVE_START_DATE
                       AND ptp.REGULAR_PAYMENT_DATE <= pet.EFFECTIVE_END_DATE)
                  AND (ptp.REGULAR_PAYMENT_DATE >= pas.EFFECTIVE_START_DATE
                       AND ptp.REGULAR_PAYMENT_DATE <= pas.EFFECTIVE_END_DATE)
                  AND (ptp.REGULAR_PAYMENT_DATE >= ppe.EFFECTIVE_START_DATE
                       AND ptp.REGULAR_PAYMENT_DATE <= ppe.EFFECTIVE_END_DATE)
                  AND (ptp.REGULAR_PAYMENT_DATE >= pay.EFFECTIVE_START_DATE
                       AND ptp.REGULAR_PAYMENT_DATE <= pay.EFFECTIVE_END_DATE)
                  AND (pet.ELEMENT_TYPE_ID IN
                             (SELECT   per.ELEMENT_TYPE_ID
                                FROM   PAY_ELEMENT_TYPE_RULES per
                               WHERE   per.ELEMENT_SET_ID = P_ELEMENT_SET_ID
                                       OR P_ELEMENT_SET_ID IS NULL))
                  AND (pet.ELEMENT_TYPE_ID IN
                             (SELECT   per.ELEMENT_TYPE_ID
                                FROM   PAY_ELEMENT_SETS_TL pes,
                                       PAY_ELEMENT_TYPE_RULES per
                               WHERE   pes.ELEMENT_SET_ID =
                                          per.ELEMENT_SET_ID
                                       AND pes.language = 'ESA'
                                       AND pes.element_set_name IN
                                                ('DEDUCCIONES_RECIBO')
                                       AND per.include_or_exclude = 'I')
                       OR (pet.CLASSIFICATION_ID IN
                                 (SELECT   per.CLASSIFICATION_ID
                                    FROM   PAY_ELEMENT_SETS_TL pes,
                                           PAY_ELE_CLASSIFICATION_RULES per
                                   WHERE   pes.ELEMENT_SET_ID =
                                              per.ELEMENT_SET_ID
                                           AND pes.language = 'ESA'
                                           AND pes.element_set_name IN
                                                    ('DEDUCCIONES_RECIBO'))
                           AND pet.ELEMENT_TYPE_ID NOT IN
                                    (SELECT   per.ELEMENT_TYPE_ID
                                       FROM   PAY_ELEMENT_SETS_TL pes,
                                              PAY_ELEMENT_TYPE_RULES per
                                      WHERE   pes.ELEMENT_SET_ID =
                                                 per.ELEMENT_SET_ID
                                              AND pes.language = 'ESA'
                                              AND pes.element_set_name IN
                                                       ('DEDUCCIONES_RECIBO')
                                              AND per.include_or_exclude =
                                                    'E')))
                  AND paa.payroll_action_id = P_PAYROLL_ACTION_ID
                  AND ppe.person_id = p_PERSON_ID
                  AND ptp.time_period_id = p_TIME_PERIOD_ID
         --            Group by pay.payroll_id
         --                  ,ptp.time_period_id
         --                  ,ppe.person_id
         --                  ,nvl(to_number(pet.attribute1),1000)
         --                  ,upper(petl.reporting_name)
         --                  ,ptp.REGULAR_PAYMENT_DATE
         --                  ,pet.element_type_id
         UNION ALL
         SELECT   pay.payroll_id,
                  ptp.time_period_id,
                  ppe.person_id,
                  UPPER (petl.reporting_name) Concepto,
                  ptp.REGULAR_PAYMENT_DATE,
                  TO_NUMBER (prv.result_value * -1) importe,
                  TO_NUMBER (prv.result_value * -1) importe_deducciones,
                  pet.element_type_id,
                  (SELECT   TO_NUMBER (prrd.result_value)
                     FROM   pay_run_result_values prrd,
                            pay_input_values_f pivd
                    WHERE   prrd.run_result_id = prr.run_result_id
                            AND prrd.INPUT_VALUE_ID = pivd.INPUT_VALUE_ID
                            AND pivd.name IN
                                     ('Days', 'Hours', 'Dias Trabajados'))
                     dias
           FROM   pay_run_results prr,
                  pay_run_result_values prv,
                  pay_element_types_f pet,
                  pay_element_types_f_tl petl,
                  pay_assignment_actions paa,
                  pay_payroll_actions ppa,
                  per_time_periods ptp,
                  per_all_assignments_f pas,
                  per_all_people_f ppe                                   ---ok
                                      ,
                  pay_all_payrolls_f pay                                 ---ok
                                        ,
                  pay_element_classifications pec                        ---ok
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
                  AND piv.name IN ('Pay Value') ---      ('ISR Subject','ISR Exempt')
                  AND prv.result_value <> '0'
                  --and    ppa.BUSINESS_GROUP_ID             =             81
                  AND pet.CLASSIFICATION_ID = pec.CLASSIFICATION_ID
                  AND paa.ASSIGNMENT_ID = pas.ASSIGNMENT_ID
                  AND ppa.TIME_PERIOD_ID = ptp.TIME_PERIOD_ID
                  AND ppa.PAYROLL_ID = pay.PAYROLL_ID
                  AND pas.PERSON_ID = ppe.PERSON_ID
                  AND (ptp.REGULAR_PAYMENT_DATE >= pet.EFFECTIVE_START_DATE
                       AND ptp.REGULAR_PAYMENT_DATE <= pet.EFFECTIVE_END_DATE)
                  AND (ptp.REGULAR_PAYMENT_DATE >= pas.EFFECTIVE_START_DATE
                       AND ptp.REGULAR_PAYMENT_DATE <= pas.EFFECTIVE_END_DATE)
                  AND (ptp.REGULAR_PAYMENT_DATE >= ppe.EFFECTIVE_START_DATE
                       AND ptp.REGULAR_PAYMENT_DATE <= ppe.EFFECTIVE_END_DATE)
                  AND (ptp.REGULAR_PAYMENT_DATE >= pay.EFFECTIVE_START_DATE
                       AND ptp.REGULAR_PAYMENT_DATE <= pay.EFFECTIVE_END_DATE)
                  AND (pet.ELEMENT_TYPE_ID IN
                             (SELECT   per.ELEMENT_TYPE_ID
                                FROM   PAY_ELEMENT_TYPE_RULES per
                               WHERE   per.ELEMENT_SET_ID = P_ELEMENT_SET_ID
                                       OR P_ELEMENT_SET_ID IS NULL))
                  AND (pet.ELEMENT_TYPE_ID IN
                             (SELECT   per.ELEMENT_TYPE_ID
                                FROM   PAY_ELEMENT_SETS_TL pes,
                                       PAY_ELEMENT_TYPE_RULES per
                               WHERE   pes.ELEMENT_SET_ID =
                                          per.ELEMENT_SET_ID
                                       AND pes.language = 'ESA'
                                       AND pes.element_set_name IN
                                                ('PERCEPCIONES NEGATIVAS_RECIBO')
                                       AND per.include_or_exclude = 'I')
                       OR (pet.CLASSIFICATION_ID IN
                                 (SELECT   per.CLASSIFICATION_ID
                                    FROM   PAY_ELEMENT_SETS_TL pes,
                                           PAY_ELE_CLASSIFICATION_RULES per
                                   WHERE   pes.ELEMENT_SET_ID =
                                              per.ELEMENT_SET_ID
                                           AND pes.language = 'ESA'
                                           AND pes.element_set_name IN
                                                    ('PERCEPCIONES NEGATIVAS_RECIBO'))
                           AND pet.ELEMENT_TYPE_ID NOT IN
                                    (SELECT   per.ELEMENT_TYPE_ID
                                       FROM   PAY_ELEMENT_SETS_TL pes,
                                              PAY_ELEMENT_TYPE_RULES per
                                      WHERE   pes.ELEMENT_SET_ID =
                                                 per.ELEMENT_SET_ID
                                              AND pes.language = 'ESA'
                                              AND pes.element_set_name IN
                                                       ('PERCEPCIONES NEGATIVAS_RECIBO')
                                              AND per.include_or_exclude =
                                                    'E')))
                  AND paa.payroll_action_id = P_PAYROLL_ACTION_ID
                  AND ppe.person_id = p_PERSON_ID
                  AND ptp.time_period_id = p_TIME_PERIOD_ID
         --            Group by pay.payroll_id
         --                  ,ptp.time_period_id
         --                  ,ppe.person_id
         --                  ,nvl(to_number(pet.attribute1),1000)
         --                  ,upper(petl.reporting_name)
         --                  ,ptp.REGULAR_PAYMENT_DATE
         --                  ,pet.element_type_id
         ORDER BY   4;  
         */
   BEGIN
   
--   imp_l(P_PAYROLL_ACTION_ID||'  '|| P_DIVISION||' '|| P_CENTRO_COSTOS||' '||P_DEPARTAMENTO||'  '|| P_PERSON_ID);
--      l_recibo_consec := P_RECIBO_INI;
--- no se deben limpiar las tablas en cada ejecucion---
      BEGIN
         DELETE FROM   XXOEM_PAY_MAESTRO_RECIBOS2
               WHERE   PAYROLL_ACTION_ID = p_PAYROLL_ACTION_ID;

---elimina percepciones de recibos que ya se ejecutaron anteriormente
DELETE FROM   XXOEM_PAY_RECIBO_PERCEPCIONES2
         WHERE   recibo_id not IN
                             (SELECT   recibo_id
                               FROM   XXOEM_PAY_MAESTRO_RECIBOS2);

---elimina deducciones que ya se allan ejecutado antes

DELETE FROM   XXOEM_PAY_RECIBO_deducciones2
         WHERE   recibo_id not IN
                             (SELECT   recibo_id
                               FROM   XXOEM_PAY_MAESTRO_RECIBOS2);

DELETE FROM   XXOEM.XXOEM_PAY_RECIBO_indem2
         WHERE   recibo_id not IN
                             (SELECT   recibo_id
                               FROM   XXOEM_PAY_MAESTRO_RECIBOS2);
                               

DELETE FROM   XXOEM.XXOEM_PAY_RECIBO_EXTRAS2
         WHERE   recibo_id not IN
                             (SELECT   recibo_id
                               FROM   XXOEM_PAY_MAESTRO_RECIBOS2);
                               
                               
 --delete from XXOEM_PAY_RECIBO_SALDOS2 where recibo_id not in (select recibo_id from XXOEM_PAY_MAESTRO_RECIBOS);

    --     DELETE FROM   XXOEM_PAY_RECIBO_PERCEPCIONES2
      --         WHERE   recibo_id NOT IN
        --                     (SELECT   recibo_id
          --                      FROM   XXOEM_PAY_MAESTRO_RECIBOS);

        -- DELETE FROM   XXOEM_PAY_RECIBO_DEDUCCIONES2
          --     WHERE   recibo_id NOT IN
            --                 (SELECT   recibo_id
              --                  FROM   XXOEM_PAY_MAESTRO_RECIBOS2);
      EXCEPTION
         WHEN OTHERS
         THEN
            imp_l('error123434:'||sqlerrm);
      END;
--imp_l('payroll_action_id= '||sqlerrm);      
  --   IMP_O('<?xml version="1.0" encoding="ISO-8859-1"?>');--para GENERAR xml
    --       IMP_O(' <G_REPORT>');
       IMP_o('A'||'|'||
             'B'||'|'||
             'C'||'|'||
             'D'||'|'||
             'E'||'|'||
             'F'||'|'||
             'G'||'|'||
             'H'||'|'||
             'I'||'|'||
             'J'||'|');
             
      FOR c_emp IN c_empleados
      LOOP
         l_recibo_num := l_recibo_consec;
         l_recibo_indice := 1;
         l_recibo_id := xxoem.XXOEM_PAY_RECIBOS_S.NEXTVAL;
         l_recibo_id1 := l_recibo_id;
         l_recibo_id2 := NULL;
         l_recibo_id3 := NULL;
         l_total_recibos := 1;
         
       -- imp_l('loop empleados   ueueud'||P_PAYROLL_ACTION_ID);
         
          /* IMP_l(rpad('H',3,' ')||
             rpad(c_emp.payroll_action_id,8,' ')||
             rpad(c_emp.numero_empleado,10,' ')||
             rpad(c_emp.fecha_pago,11,' ')||
            rpad(c_emp.fecha_inicial,11,' ')||
             rpad(c_emp.fecha_final,9,' ')||
             rpad(c_emp.dias_pagados,3,' ')||
             rpad(c_emp.salario_Base_Cot,5,' ')||c_emp.SDI||
                     c_emp.decripcion);
            */ 
             
        
             
             IMP_o('H'||'|'||
             c_emp.payroll_action_id||'|'||
             c_emp.numero_empleado||'|'||
             c_emp.fecha_pago||'|'||
             c_emp.fecha_inicial||'|'||
             c_emp.fecha_final||'|'||
             c_emp.dias_pagados||'|'||
             c_emp.salario_Base_Cot
             ||'|'||
             c_emp.SDI||'|'||
             c_emp.decripcion||'|'||
             c_emp.num_seg_social||'|'--||
             --c_emp.neto_total||'|'
             );
             

------------------------------------------------------------------  
--           imp_l('  <EMPLEADOS>');
--             imp_l(g_xml('ID','H'));
--             imp_l(g_xml('ID_NOMINA',c_emp.id_nomina));
--             imp_l(g_xml('NUMERO_EMPLEADO',c_emp.numero_empleado));
--             imp_l(g_xml('FECHA_PAGO',c_emp.fecha_pago));
--             imp_l(g_xml('FECHA_INICIAL',c_emp.fecha_inicial));
--             imp_l(g_xml('FECHA_FINAL',c_emp.fecha_final));
--             imp_l(g_xml('NUMERO_DIAS',c_emp.dias_pagados));
--             imp_l(g_xml('DIAS_BASE_COT',c_emp.salario_Base_Cot));
--             imp_l(g_xml('SDI',c_emp.SDI));
--             imp_l(g_xml('DESCRIPCION',c_emp.decripcion));
--           
         --- Genera el primer recibo
         
        INSERT INTO XXOEM_HR_CFDI_EMPLEADOS (recibo_id,   
                                                ID_NOMINA,
                                                numero_empleado,
                                                fecha_pago,
                                                fecha_inicial,
                                                fecha_final,
                                                dias_pagados,
                                                salario_Base_Cot,
                                                SDI ,
                                                decripcion,
                                                TIME_PERIOD_ID,
                                                PERSON_ID,      
                                                PAYROLL_ACTION_ID,
                                                ID_DATOS,
                                                NUM_SEGURO_SOCIAL)
           VALUES   (l_recibo_id,
                     c_emp.id_nomina,
                     c_emp.numero_empleado,                            --listo
                     c_emp.fecha_pago,
                     c_emp.fecha_inicial,
                     c_emp.fecha_final,
                     c_emp.dias_pagados,
                     nvl(c_emp.salario_Base_Cot,0),
                     c_emp.SDI,
                     c_emp.decripcion,
                    -- c_emp.FULL_NAME,
                     c_emp.time_period_id,
                     c_emp.person_id,                                  --listo
                    -- c_emp.DEPARTAMENTO,                               --listo
                    -- c_emp.ELEMENT_SET_ID,                             --listo
                    -- c_emp.location_code,                              --listo
                     c_emp.payroll_action_id,                          --listo
                     --c_emp.division,                                   --listo
                     --c_emp.centro_costos                               --listo
                     'H'
                     ,c_emp.num_seg_social
                                        );
                                        
              
                     
   --         imp_l('loop empleados');
         -- Genera los registros para los saldos
         /*
         l_indice_sdo := 0;
         l_total_sdo  := 0;
         for c_sal in c_saldos(c_emp.PAYROLL_ACTION_ID, c_emp.person_id, c_emp.time_period_id) loop
             l_indice_sdo := l_indice_sdo + 1;
             l_total_sdo  := l_total_sdo  + 1;
             -- crea un nuevo recibo si es necesario
             begin
               insert into xxoem.XXOEM_PAY_RECIBO_SALDOS2 (RECIBO_ID, NUM_LINEA, CONCEPTO, SALDO)
               values (l_recibo_id,l_indice_sdo,c_sal.concepto,c_sal.saldo  );
             exception
               when others then
                  XXOEM.XXOEM_PAY_UTILS_PKG.vlog(sqlerrm);
             end ;
         end loop;
    --     completa_saldos (l_recibo_id,l_indice_sdo);
    */
         -- Genera los registros para las percepciones
         l_indice_per := 0;
         l_total_per := 0;
         l_recibo_id := l_recibo_id1;
/*imprime en registro */        /*        imp_l('for percepciones: set_id'||c_emp.ELEMENT_SET_ID||' payrroll> '||c_emp.PAYROLL_ACTION_ID||' person> '||
                                      c_emp.person_id||' timeperiod> '||c_emp.time_period_id);
*/
         FOR c_per IN c_percepciones (null,--P_ELEMENT_SET_ID,
                                      c_emp.PAYROLL_ACTION_ID,
                                      c_emp.person_id,
                                      c_emp.time_period_id)
         LOOP
            l_indice_per := l_indice_per + 1;
            l_total_per := l_total_per + 1;
      --          imp_l('loop percepciones');
            BEGIN
        --    imp_l('loop percepciones begin');
            
            
            if (c_per.concepto=substr('REPARTO DE UTILIDADES',0,15)) then
                 descripcion_per:='Participación de los Trabajadores en las Utilidades PTU';--descripcion
                 TIPO_per:='003';--tipo de percepcion
                 valor_exento:=c_per.exento;
            elsif (c_per.concepto=substr('SUBSIDIO ISR PARA EMPLEO',0,15)) then
                descripcion_per:='Subsidio para el empleo';
                TIPO_per:='017';
                valor_exento:=c_per.importe;
            elsif (c_per.concepto='1600 CUOTA OBRE') then
                descripcion_per:=C_PER.descripcion_percepcion;
                TIPO_PER:=c_per.TIPO_PERCEPCION;
                valor_exento:=c_per.importe;
            elsif (c_per.concepto LIKE '%VALES%D') then
                descripcion_per:=C_PER.descripcion_percepcion;
                TIPO_PER:=c_per.TIPO_PERCEPCION;
                valor_exento:=c_per.importe;
            elsif (c_per.concepto LIKE '1130%') then
                descripcion_per:=C_PER.descripcion_percepcion;
                TIPO_PER:=c_per.TIPO_PERCEPCION;
                valor_exento:=c_per.importe;
            elsif (c_per.concepto LIKE '1131%') then
                descripcion_per:=C_PER.descripcion_percepcion;
                TIPO_PER:=c_per.TIPO_PERCEPCION;
                valor_exento:=c_per.importe;
            else 
            --descripcion_per:=c_per.concepto;
            descripcion_per:=C_PER.descripcion_percepcion;
            TIPO_PER:=c_per.TIPO_PERCEPCION;
            valor_exento:=c_per.exento;
            end if;
            
            
            
          /*   IMP_l(rpad('P',3,' ')||
             rpad(SUBSTR(c_per.concepto,0,15),20,' ')||
             rpad(TIPO_per,6,' ')||
             rpad(descripcion_per,70,' ')||
             rpad(c_per.gravado,10,' ')||
             rpad(c_per.exento,10,' '));
            */ 
            
            
       IMP_o('P'||'|'||
             TIPO_per||'|'||
             SUBSTR(c_per.concepto,0,15)||'|'||
             descripcion_per||'|'||
             c_per.gravado||'|'||
             valor_exento||'|');

             
             
            /* IMP_o(rpad('P',3,' ')||
             rpad(SUBSTR(c_per.concepto,0,15),20,' ')||
             rpad(TIPO_per,6,' ')||
             rpad(descripcion_per,70,' ')||
             rpad(c_per.gravado,10,' ')||
             rpad(c_per.exento,10,' '));*/
--             
--                IMP_O('  <PERCEPCIONES>');
--             imp_o(g_xml('IDP','P'));
--             imp_o(g_xml('CLAVE',SUBSTR(c_per.concepto,0,15)));--CLAVE PERCEPCION
--             imp_o(g_xml('TIPO',TIPO_per));----TIPO PERCEPCION
--             imp_o(g_xml('DESCRIPCION',descripcion_per--c_per.descripcion_percepcion
--             ));
--             imp_o(g_xml('IMPORTE_GRAVADO',c_per.gravado));
--             imp_o(g_xml('IMPORTE_EXENTO',c_per.exento));
----         
-------------------------------------------------------------------------------------------
--    imp_o(g_xml('NUMERO_DIAS',c_emp.dias_pagados));
--             imp_o(g_xml('DIAS_BASE_COT',c_emp.salario_Base_Cot));
--             imp_o(g_xml('SDI',c_emp.SDI));
--             imp_o(g_xml('DESCRIPCION',c_emp.decripcion));


            --IMP_O('  </PERCEPCIONES>');
            
INSERT INTO XXOEM_HR_CFDI_PERCEPCIONES (
                                                RECIBO_ID ,
NUM_LINEA ,
CLAVE ,--CONCEPTO,
TIPO_PER ,
DESCRIPCION_PER ,
IMPORTE ,
IMPORTE_PERCEPCIONES,
ELEMENT_TYPE_ID ,
DIAS_PER ,
GRAVADO_PER ,
EXENTO_PER ,
ID_DATOS                  )
                 VALUES   (l_recibo_id,
                           l_indice_per,
                           SUBSTR(c_per.concepto,0,15),--CLAVE
                           TIPO_PER,--c_per.TIPO_PERCEPCION,--TIPO
                           descripcion_per,--c_per.descripcion_percepcion,--DESCRIPCION
                           c_per.importe,
                           c_per.importe_percepciones,
                           c_per.element_type_id,
                           c_per.dias,
                           c_per.gravado,
                           c_per.exento,                                                      
                           'P'
                           );            
                     
              
                         
                           
            EXCEPTION
               WHEN OTHERS
               THEN
                  --XXOEM.XXOEM_PAY_UTILS_PKG.vlog (SQLERRM);
                  imp_l('error percepciones '||SQLERRM);
            END;
         END LOOP;

         --   completa_percepciones (l_recibo_id,l_indice_per);

         -- Genera los registros para las deducciones
         l_indice_ded := 0;
         l_total_ded := 0;
         l_recibo_id := l_recibo_id1;

         FOR c_ded IN c_deducciones (null,--c_emp.ELEMENT_SET_ID,--
                                     c_emp.PAYROLL_ACTION_ID,
                                     c_emp.person_id,
                                     c_emp.time_period_id)
         LOOP
            l_indice_ded := l_indice_ded + 1;
            l_total_ded := l_total_ded + 1;

            BEGIN
            
    --        imp_l('loop deducciones');
            
            if (c_ded.CONCEPTO='3100 DESCUENTO CUOTA OBRERA IMSS') then
                descripcion_ded:='Seguridad social';
                TIPO_ded:='001';
                elsif (c_ded.CONCEPTO='ISR') then
                descripcion_DED:='ISR';
                TIPO_ded:='002';
                else
                descripcion_DED:=C_DED.descripcion_DEDUCCION;
                TIPO_DED:=C_DED.TIPO_DEDUCCION;
                end if;
            --20,3,20,6,70,10,10
            -- IMP_l(rpad('DEDUCCIONES',20,' ')||
      /*       imp_l(rpad('D',3,' ')||
            rpad(SUBSTR(c_ded.concepto,0,15),20,' ')||
             rpad(TIPO_ded,6,' ')||
             rpad(descripcion_DED,70,' ')||
             rpad(c_DED.gravado,10,' ')||
             rpad(c_DED.over_by,10,' '));
        */     
             imp_o('D'||'|'||
                   TIPO_ded||'|'||
             SUBSTR(c_ded.concepto,0,15)||'|'||
                    descripcion_DED||'|'||
                    c_DED.exento||'|'||
                    c_DED.over_by||'|');
/*             
             imp_o(rpad('D',3,' ')||
             rpad(SUBSTR(c_ded.concepto,0,15),20,' ')||
             rpad(TIPO_ded,6,' ')||
             rpad(descripcion_DED,70,' ')||
             rpad(c_DED.gravado,10,' ')||
             rpad(c_DED.over_by,10,' '));*/
--             
--             imp_o(g_xml('IDD','D'));
--             imp_o(g_xml('TIPO',TIPO_ded--c_ded.TIPO_DEDUCCION
--             ));
--             imp_o(g_xml('CLAVE',SUBSTR(c_ded.concepto,0,15)
--             ));
--             imp_o(g_xml('CONCEPTO',descripcion_DED--c_ded.descripcion_DEDUCCION
--             ));
--             imp_o(g_xml('IMPORTE_GRAVADO',c_DED.gravado));
--             imp_o(g_xml('IMPORTE_EXENTO',c_DED.over_by));
--           IMP_O('  </DEDUCCIONES>');
           
           
               INSERT INTO XXOEM_HR_CFDI_DEDUCCIONES 
(
RECIBO_ID ,
NUM_LINEA ,
CLAVE_DED ,
ELEMENT_TYPE_ID ,
DIAS_DED ,
GRAVADO_DED ,
EXENTO_DED ,
TIPO_DED ,
DESCRIPCION_DED,
ID_DATOS 
  )
                 VALUES   (l_recibo_id,
                           l_indice_ded,
                           SUBSTR(c_ded.concepto,0,15),
                          -- c_ded.importe,
                          -- c_ded.importe_deducciones,
                           c_ded.element_type_id,
                           c_ded.dias,
                           c_DED.gravado,
                           c_DED.over_by,
                           TIPO_ded,-- c_ded.TIPO_DEDUCCION,
                           descripcion_DED ,--c_ded.descripcion_DEDUCCION,
                           'D'
                           );
            
            EXCEPTION
               WHEN OTHERS
               THEN
                  --XXOEM.XXOEM_PAY_UTILS_PKG.vlog (SQLERRM);
                  imp_l('error deducciones '||SQLERRM);
            END;
         END LOOP;

      
       -- Genera los registros para las incapacidades
         l_indice_inc := 0;
         l_total_inc := 0;
         l_recibo_id := l_recibo_id1;

         FOR c_inc IN c_incapacidades (--null,--P_ELEMENT_SET_ID,
                                     c_emp.PAYROLL_ACTION_ID,
                                     c_emp.person_id,
                                     c_emp.time_period_id)
         LOOP
            l_indice_INC := l_indice_INC + 1;
            l_total_INC := l_total_INC + 1;

            BEGIN
          --8,10,9  
            -- imp_l('loop incapacidades');
--             
/*             imp_l(rpad('I',3,' ')||
             rpad(c_inc.dias,8,' ')||
             rpad(c_INC.concepto,70,' ')||
             rpad(c_inc.importe,9,' '));  */
--             
              imp_o('I'||'|'||
             c_inc.dias||'|'||
             c_INC.concepto||'|'||
             c_inc.importe||'|');
            
                   /*      imp_o(rpad('I',3,' ')||
             rpad(c_inc.dias,8,' ')||
             rpad(c_INC.concepto,70,' ')||
             rpad(c_inc.importe,9,' '));*/

--            IMP_O('  <INCAPACIDADES>');
--             imp_o(g_xml('IDI','I'));
--             imp_o(g_xml('DIAS',c_inc.dias));
--             imp_o(g_xml('TIPO_INCAPACIDAD',c_INC.concepto));
--             imp_o(g_xml('DESCUENTO',c_inc.importe));
--            IMP_O('  </INCAPACIDADES>');
            
              INSERT INTO XXOEM_HR_CFDI_INCAPACIDADES (   
RECIBO_ID ,
NUM_LINEA ,
TIPO_INC ,
DESCUENTO_INC,
ELEMENT_TYPE_ID ,
DIAS_INC ,
ID_DATOS 
)
                 VALUES   (l_recibo_id,
                           l_indice_ded,
                           c_inc.concepto,
                           c_inc.importe,
                           --c_inc.importe_deducciones,
                           c_inc.element_type_id,
                           c_inc.dias,
                           'I'
                           );
              
            EXCEPTION
               WHEN OTHERS
               THEN
            --      XXOEM.XXOEM_PAY_UTILS_PKG.vlog (SQLERRM);
            imp_l('error incapacidades'||SQLERRM);
            END;
         END LOOP;


       -- Genera los registros para las incapacidades
         l_indice_EX := 0;
         l_total_EX := 0;
         l_recibo_id := l_recibo_id1;

         FOR c_EXT IN c_H_EXTRAS (--null,--P_ELEMENT_SET_ID,
                                     c_emp.PAYROLL_ACTION_ID,
                                     c_emp.person_id,
                                     c_emp.time_period_id)
         LOOP
            l_indice_EX := l_indice_EX + 1;
            l_total_EX := l_total_EX + 1;
            -------------SACA TIPO DE HORAS-----
            --imp_o(C_EXT.CONCEPTO);
            
            IF (C_EXT.CONCEPTO ='1290 TIEMPO EXTRA TOTAL DOBLE') THEN
            TIPO_HORAS:='DOBLES';
            
            ELSIF (C_EXT.CONCEPTO = '1300 TIEMPO EXTRA TOTAL TRIPLE') THEN
            TIPO_HORAS:='TRIPLES';
            END IF;
 
/*           
            IF (c_EXT.HORAS_EXTRAS>0 AND c_EXT.HORAS_EXTRAS<=1) THEN 
            DIAS_EXTRA:=1;
            ELSIF (c_EXT.HORAS_EXTRAS>1 AND c_EXT.HORAS_EXTRAS<=2) THEN
            DIAS_EXTRA:=2;
            ELSIF (c_EXT.HORAS_EXTRAS>2) THEN
            DIAS_EXTRA:=3;
            END IF;
  */          
            
            BEGIN
--            
/*            imp_l(rpad('E',3,'|')||
             rpad(DIAS_EXTRA,3,'|')||
             rpad(TIPO_HORAS,10,'|')||
             rpad(c_EXT.HORAS_EXTRAS,3,'|')||
             rpad(c_EXT.importe_PAGADO,6,'|'));
             
             imp_o('E'||'|'||
             DIAS_EXTRA||'|'||
             TIPO_HORAS||'|'||
             c_EXT.HORAS_EXTRAS||'|'||
             c_EXT.importe_PAGADO||'|');
*/  
           /*
           imp_o(rpad('E',3,' ')||
             rpad(DIAS_EXTRA,3,' ')||
             rpad(TIPO_HORAS,10,' ')||
             rpad(c_EXT.HORAS_EXTRAS,3,' ')||
             rpad(c_EXT.importe_PAGADO,6,' '));*/


imp_o('E'||'|'||
      c_ext.dias||'|'||
      TIPO_HORAS||'|'||
      c_EXT.HORAS_EXTRAS||'|'||
      c_EXT.importe_PAGADO||'|');

--        --    imp_l('loop horas extras');

--            IMP_O('  <HORAS_EXTRA>');
--             imp_o(g_xml('IDE','E'));
--             imp_o(g_xml('DIAS',DIAS_EXTRA));
--             imp_o(g_xml('TIPO_HORAS',TIPO_HORAS));
--             imp_o(g_xml('HORAS_EXTRA',c_EXT.HORAS_EXTRAS));
--             imp_o(g_xml('IMPORTE_PAGADO',c_EXT.importe_PAGADO));
--             
--             
             --------------------------------------------------
--             imp_o(g_xml('IMPORTE_EXENTO',c_DED.exento));
----             imp_o(g_xml('NUMERO_DIAS',c_emp.dias_pagados));
--             imp_o(g_xml('DIAS_BASE_COT',c_emp.salario_Base_Cot));
--             imp_o(g_xml('SDI',c_emp.SDI));
--             imp_o(g_xml('DESCRIPCION',c_emp.decripcion));
--            IMP_O('  </HORAS_EXTRA>');
               
INSERT INTO XXOEM_HR_CFDI_HORASEXTRAS (   RECIBO_ID ,
                                                                   NUM_LINEA ,
                                                                   TIPO_HORAS ,
                                                                   IMPORTE_PAGADO ,
                                                                   ELEMENT_TYPE_ID ,
                                                                   HORAS_EXTRAS ,
                                                                   DIAS_EXTRAS ,
                                                                   ID_DATOS                                                                   
                          )
                 VALUES   (l_recibo_id,
                           l_indice_ded,
                           TIPO_HORAS,--c_EXT.concepto,
                           c_EXT.importe_PAGADO,
                           --c_inc.importe_deducciones,
                           c_EXT.element_type_id,
                           c_EXT.HORAS_EXTRAS,
                           c_ext.dias,
                           'E'
                           );
                           
                                        
            EXCEPTION
               WHEN OTHERS
               THEN
                 imp_l('error extras'||SQLERRM);
            END;
         END LOOP;

       -- completa_deducciones  (l_recibo_id,l_indice_ded);
       
  --              IMP_O('  </EMPLEADOS>');

         l_recibo_consec := l_recibo_consec + 1;
      END LOOP;
    --   IMP_O(' </G_REPORT>');
       exception when others then 
       imp_l('error empleados  '||sqlerrm);
   END;


   FUNCTION P_DEFINED_BALANCE_ID (ass_action_id IN NUMBER)
      RETURN NUMBER
   IS
      p_defined   NUMBER;
   BEGIN/*
      SELECT   DEFINED_BALANCE_ID
        INTO   p_defined
        FROM   PAY_BALANCES_V
       WHERE   (   (business_group_id = 81)
                OR (business_group_id IS NULL AND legislation_code = 'MX')
                OR (business_group_id IS NULL AND legislation_code IS NULL))
               AND (assignment_action_id = ass_action_id            -- 3743833
                                                        )
               AND (BALANCE_NAME_AND_SUFFIX='Dias Cuota Seguridad Social 1_ASG_GRE_RUN');*/
         Select pdb.DEFINED_BALANCE_ID 
         INTO   p_defined
                       from pay_defined_balances  pdb
                           , pay_balance_types bttl
                           , pay_balance_dimensions bm
                       where pdb.BALANCE_TYPE_ID = bttl.BALANCE_TYPE_ID
                       and   pdb.BALANCE_DIMENSION_ID = bm.BALANCE_DIMENSION_ID
                       and   bttl.balance_name = 'Dias Cuota Seguridad Social 1'
                       and   bm.LEGISLATION_CODE = 'MX'
                       and   bm.DATABASE_ITEM_SUFFIX = '_ASG_GRE_RUN'  ;    

      RETURN p_defined;
   EXCEPTION
      WHEN OTHERS
      THEN
         XXOEM.XXOEM_PAY_UTILS_PKG.vlog (SQLERRM);
         imp_l('balanceid : '||sqlerrm);
         
         RETURN 0;
   END;
   
   
      FUNCTION F_REGRESA_SDI (PIVID IN NUMBER, P_RRID IN NUMBER)
      RETURN NUMBER
   IS
      P_SDI   NUMBER;
   BEGIN
      select PRV.RESULT_VALUE SDI
               into P_SDI
                from  
                    pay_run_results prr,
                    pay_run_result_values prv
                    ,PAY_ELEMENT_TYPES_F ETY,
                    PAY_ELEMENT_TYPES_F_TL ETYTL,
                    pay_input_values_f piv-----
                 where 1=1
                   AND prv.INPUT_VALUE_ID = piv.INPUT_VALUE_ID-------
                   AND prr.RUN_RESULT_ID = prv.RUN_RESULT_ID
                   AND PRR.ELEMENT_TYPE_ID = ETY.ELEMENT_TYPE_ID  
                   AND ETY.element_type_id = ETYTL.element_type_id
                   AND ETYTL.LANGUAGE = 'ESA'--USERENV ('LANG')
                   AND (ETYTL.ELEMENT_NAME = 'I7001 SDI')
                   AND piv.name IN ('Pay Value')--------
                   and piv.INPUT_VALUE_ID= PIVID
                   and prv.RUN_RESULT_ID=P_RRID;

               dbms_output.put_line('INPUT_VALUE_ID: '||PIVID);
               dbms_output.put_line('RUN_RESULT_ID: '||P_RRID);

      RETURN p_sdi;
   EXCEPTION
      WHEN OTHERS
      THEN
         --XXOEM.XXOEM_PAY_UTILS_PKG.vlog (SQLERRM);
         imp_l('error sdi: '||sqlerrm);
         RETURN 0;
   END;

   
--  procedure CREA_RECIBO_NOMINA(P_PAYROLL_ACTION_ID  Number,
--                            P_ELEMENT_SET_ID     Number,
--                            P_DIVISION           Varchar2,
--                            P_CENTRO_COSTOS      Varchar2,
--                            P_DEPARTAMENTO       Varchar2,
--                            P_PERSON_ID          Number,
--                            P_EMP_NUM_INI        Varchar2,
--                            P_EMP_NUM_FIN        Varchar2,
--                            P_LOCATION_CODE      Varchar2,
--                            P_RECIBO_INI          Number
--                           ) is
-----CURSOR DE DATOS DE LA CABECERA DEL RECIBO DE NOMINA----
--CURSOR HEADER_RECIBO() IS
-- SELECT recibo_id, recibo_num CONSECUTIVO, creation_date, payroll_id, payroll_name,
--       person_id, employee_number, full_name, time_period_id, period_name,
--       rfc, imss, curp, departamento, puesto, compania, rfc_cia, pay_basis_id,
--       grade_id, assignment_id, start_date, cut_off_date, element_set_id,
--       assignment_action_id, location_code, payroll_action_id, per_ini,
--       per_fin, period_num, division, centro_costos, depto,
--       soft_coding_keyflex_id
--  FROM xxoem_pay_maestro_recibos
--where 1=1

--and      payroll_action_id     = :P_PAYROLL_ACTION_ID
--and      (element_set_id = :P_ELEMENT_SET_ID  or :P_ELEMENT_SET_ID is null)
--and      (division             = :P_DIVISION  or :P_DIVISION is null)
--and      (centro_costos = :P_CENTRO_COSTOS  or :P_CENTRO_COSTOS is null)
--and      (departamento = :P_DEPARTAMENTO  or :P_DEPARTAMENTO is null)
--and      (person_id = :P_PERSON_ID  or :P_PERSON_ID is null)
--and      employee_number >= NVL(:P_EMP_NUM_INI,EMPLOYEE_NUMBER)
--and      employee_number <= NVL(:P_EMP_NUM_FIN,EMPLOYEE_NUMBER)
--and      location_code  = NVL(:P_LOCATION_CODE, location_code)
--order by recibo_id, recibo_num
--
-- END;
END;
/
