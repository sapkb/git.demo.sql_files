begin
  fnd_global.set_nls_context('LATIN AMERICAN SPANISH');
end;


/* Formatted on 09/01/2014 10:10:17 a.m. (QP5 v5.115.810.9015) */
--- Cursor para PERCEPCIONES ----
  --   cursor c_percepciones (P_ELEMENT_SET_ID number, p_PAYROLL_ACTION_ID  number, p_person_id number, p_time_period_id number) is

  SELECT   PAYROLL_ID,
           RUN_RESULT_ID,
           TIME_PERIOD_ID,
           PERSON_ID,
           TIPO_PERCEPCION,
           gravado,
           exento,
           NUM_ELEM_DEDUC_ORD,
           CONCEPTO,
           REGULAR_PAYMENT_DATE,
           IMPORTE,
           IMPORTE_PERCEPCIONES,
          -- ELEMENT_TYPE_ID,
           DIAS
    FROM   (  SELECT   pay.payroll_id,
                       ptp.time_period_id,
                       ppe.person_id,
                       pRV.RUN_RESULT_ID                                 --efe
                      ,pet.ATTRIBUTE1 TIPO_PERCEPCION,
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
                                                                              )),
                          0
                       )
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
                                                                              )),
                          0
                       )
                          exento,
                       NVL (TO_NUMBER (pet.attribute1), 1000) num_elem_deduc_ord,
                       UPPER (petl.reporting_name) Concepto,
                       ptp.REGULAR_PAYMENT_DATE,
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
                                               :P_ELEMENT_SET_ID
                                            OR:P_ELEMENT_SET_ID IS NULL))
                       AND (pet.ELEMENT_TYPE_ID IN
                                  (SELECT   per.ELEMENT_TYPE_ID
                                     FROM   PAY_ELEMENT_SETS_TL pes,
                                            PAY_ELEMENT_TYPE_RULES per
                                    WHERE   pes.ELEMENT_SET_ID =
                                               per.ELEMENT_SET_ID
                                            AND pes.language = 'ESA'
                                            AND pes.element_set_name IN
                                                     ('PERCEPCIONES_RECIBO')
                                            AND per.include_or_exclude = 'I')
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
                                                   AND pes.language = 'ESA'
                                                   AND pes.element_set_name IN
                                                            ('PERCEPCIONES_RECIBO')
                                                   AND per.include_or_exclude =
                                                         'E')))
                       AND paa.payroll_action_id = :P_PAYROLL_ACTION_ID --162847
                       AND ppe.person_id = :p_PERSON_ID                --11069
             --          AND ptp.time_period_id = :p_TIME_PERIOD_ID       --5698
            GROUP BY   pay.payroll_id,
                       ptp.time_period_id,
                       ppe.person_id,
                       NVL (TO_NUMBER (pet.attribute1), 1000),
                       UPPER (petl.reporting_name),
                       ptp.REGULAR_PAYMENT_DATE,
                       pet.element_type_id,
                       pRV.RUN_RESULT_ID                                 --efe
                                        )
   WHERE   importe_percepciones <> 0
ORDER BY   4;