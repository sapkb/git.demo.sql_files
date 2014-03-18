begin
  fnd_global.set_nls_context('LATIN AMERICAN SPANISH');
end;


/* Formatted on 08/01/2014 05:28:31 p.m. (QP5 v5.115.810.9015) */
--------------------------BALANCE id----------------
 SELECT  
 -- BALANCE_NAME_AND_SUFFIX,
--           D_CURRENCY_CODE,
--           D_BALANCE_UOM,
--           ASSIGNMENT_ACTION_ID,
           DEFINED_BALANCE_ID
--           BALANCE_DIMENSION_ID,
--           LATEST_BALANCE_EXIST,
--           C_BALANCE_UOM
    FROM   PAY_BALANCES_V
   WHERE   ( (business_group_id = 81)
            OR 
            (business_group_id IS NULL AND legislation_code = 'MX')
            OR (business_group_id IS NULL AND legislation_code IS NULL))
           AND (assignment_action_id = 3743833)
           AND (BALANCE_NAME_AND_SUFFIX LIKE 'Dias Cuota Seguridad Social 1_ASG_GRE_RUN')
ORDER BY   latest_balance_exist DESC, balance_name_and_suffix


/* Formatted on 08/01/2014 06:28:29 p.m. (QP5 v5.115.810.9015) */
------------SDI--------
  SELECT   ELEMENT_NAME,
           CLASSIFICATION_NAME,
           OUTPUT_CURRENCY_CODE,
           MODIFIED,
           UNITS,
           START_DATE,
           END_DATE,
           ASSIGNMENT_ACTION_ID,
           RUN_RESULT_ID,
           RESULT_VALUE,
           UOM,
           INPUT_VALUE_ID
    FROM   PAY_RUN_RESULTS_V
   WHERE 1=1
   AND ELEMENT_NAME = 'I7001 SDI' 
   AND  ASSIGNMENT_ACTION_ID = 3439967
ORDER BY   processing_priority, run_result_id