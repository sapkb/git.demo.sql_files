

    
    create or replace view FDI_Nomina
    (id_no,id_nomina
    ,numero_empleado
    ,fecha_pago,
                     fecha_inicial,
                     fecha_final,
                     dias_pagados,
                     salario_Base_Cot,
                     decripcion,
                     id_percepcion,
                    TIPO_PERCEPCION,
                    CLAVE ,
                    concepto_percepcion,
                    IMPORTEGRAVADO_per ,
                     IMPORTEEXENTO_per ,
                     id_decuccion,
                      tipo_decuccion,
                      clave_deduccion,
                      CONCEPTO_deduccion,
                      IMPORTEGRAVADO_ded ,
                      iMPORTEEXENTO_ded ,
                      id_inca,
                      DIAS_incapacidad,
                      tipo_incapacidad,
                      descuento,
                      id_he,
                      DIAS_EXTRAS,
                      tipo_horas,
                      HORAS_EXTRAS,
                      IMPORTE_PAGADO)
    as
    select 'H',
                     prm.ID_NOMINA,
                     prm.numero_empleado, 
                     prm.fecha_pago,
                     prm.fecha_inicial,
                     prm.fecha_final,
                     prm.dias_pagados,
                     prm.salario_Base_Cot,
                     prm.decripcion,
                     'P',
                     prp.TIPO_PERCEPCION,
                     prp.CLAVE,--CONCEPTO,
                     prp.DESCRIPCION,
                     prp.IMPORTEGRAVADO ,
                     prp.IMPORTEEXENTO ,
                     'D',
                      prd.segment2,
                      prd.segment5,
                      prd.CONCEPTO,
                      prd.IMPORTEGRAVADO ,
                      prd.IMPORTEEXENTO ,
                      'I',
                      pri.DIAS,
                      pri.CONCEPTO,
                      pri.IMPORTE,
                      'E',
                      pre.DIAS_EXTRAS,
                      pre.CONCEPTO,
                      pre.HORAS_EXTRAS,
                      pre.IMPORTE_PAGADO
          from XXOEM_PAY_MAESTRO_RECIBOS2 PRM,
                xxoem.XXOEM_PAY_RECIBO_PERCEPCIONES2 PRP, 
                xxoem.XXOEM_PAY_RECIBO_DEDUCCIONES2 PRD,
                XXOEM.XXOEM_PAY_RECIBO_indem2 pri,
                XXOEM.XXOEM_PAY_RECIBO_EXTRAS2 pre
           where 1=1
           and prm.recibo_id=prp.recibo_id
           and prp.recibo_id=prd.recibo_id
           --and prd.recibo_id=pri.recibo_id
           --and pri.recibo_id=nvl(pre.recibo_id,pri.recibo_id)