ALTER TABLE hr.report_jobs_config ADD (
  report_id VARCHAR2(50), 
-- Ej: 'REP_VENTAS_MENSUAL'    
  sp_name   VARCHAR2(100) 
-- Ej: 'HR.SP_MIGRAR_VENTAS'
);

ALTER TABLE hr.report_jobs_config ADD (
  parametros_json CLOB -- Aquí Java guardará un JSON con todo lo que el reporte necesite
);

-- En lugar de usar el objeto CHAIN de Oracle (que es genial pero muy verboso para 50 flujos idénticos y lineales), creamos un único Procedimiento Almacenado Maestro.

CREATE OR REPLACE PROCEDURE hr.sp_master_orquestador (
  p_report_id VARCHAR2
) AS
  v_sp_name VARCHAR2(100);
BEGIN
-- 1. Buscamos qué SP pesado corresponde a este reporte
  SELECT
    sp_name
  INTO v_sp_name
  FROM
    hr.report_jobs_config
  WHERE
    report_id = p_report_id;

    -- 2. Ejecutamos el SP pesado de forma dinámica (El Paso A)
    -- Si dura 5 horas, se quedará aquí esperando sin colgar a Java
  EXECUTE IMMEDIATE 'BEGIN '
                    || v_sp_name
                    || '; END;';

    -- 3. Si termina bien, notificamos a Java (El Paso B)    
  hr.sp_notificar_java('generar', p_report_id);
EXCEPTION
  WHEN OTHERS THEN
    -- Si el SP dinámico falla en la hora 4, entra aquí automáticamente        
    hr.sp_notificar_java('error', p_report_id);
        -- Opcional: Registrar en una tabla de logs el error detallado (SQLERRM)        
    RAISE; 
        -- Para que el job quede en estado FAILED en Oracle
END;
/

-- Ejemplo de lo que Java mandaría a crear para el reporte 1:
BEGIN
  dbms_scheduler.create_job(
    job_name        => 'JOB_REP_VENTAS',
    job_type        => 'PLSQL_BLOCK',
    job_action      => 'BEGIN hr.sp_master_orquestador(''REP_VENTAS_MENSUAL''); END;',
    start_date      => systimestamp,
    repeat_interval => 'FREQ=DAILY;BYHOUR=23;BYMINUTE=0', -- 11:00 PM    
    enabled         => TRUE
  );
END;
/
    -- Ejemplo para el reporte 45 (totalmente distinto):
BEGIN
  dbms_scheduler.create_job(
    job_name        => 'JOB_REP_INVENTARIO',
    job_type        => 'PLSQL_BLOCK',
    job_action      => 'BEGIN hr.sp_master_orquestador(''REP_INVENTARIO_SEMANAL''); END;',
    start_date      => systimestamp,
    repeat_interval => 'FREQ=WEEKLY;BYDAY=SUN;BYHOUR=2;BYMINUTE=0', -- Dom 2:00 AM    
    enabled         => TRUE
  );
END;
/

-- Todos los SPs de reportes deben recibir el ID del reporte y el JSON
PROCEDURE sp_migrar_ventas (
  p_report_id    VARCHAR2,
  p_json_payload CLOB
);

PROCEDURE sp_migrar_inventario (
  p_report_id    VARCHAR2,
  p_json_payload CLOB
);

CREATE OR REPLACE PROCEDURE hr.sp_master_orquestador (
  p_report_id VARCHAR2
) AS
  v_sp_name VARCHAR2(100);
  v_json    CLOB;
BEGIN-- 1. Buscamos el SP y los parámetros guardados por Java
  SELECT
    sp_name,
    parametros_json
  INTO
    v_sp_name,
    v_json
  FROM
    hr.report_jobs_config
  WHERE
    report_id = p_report_id;

    -- 2. Ejecución dinámica pasando el JSON como argumento (Usando bind variables para seguridad)
  EXECUTE IMMEDIATE 'BEGIN '
                    || v_sp_name
                    || '(:1, :2); END;'
    USING p_report_id, v_json;

    -- 3. Notificar éxito a Java    
  hr.sp_notificar_java('generar', p_report_id);
EXCEPTION
  WHEN OTHERS THEN
    hr.sp_notificar_java('error', p_report_id);
    RAISE;
END;
/

CREATE OR REPLACE PROCEDURE hr.sp_migrar_ventas (
  p_report_id    VARCHAR2,
  p_json_payload CLOB
) AS
  v_fecha_inicio DATE;
  v_sucursal_id  NUMBER;
BEGIN-- 1. Extraer los parámetros específicos de este reporte desde el JSON
    -- Ejemplo del JSON que mandó Java: {"fecha_inicio": "2023-10-01", "sucursal_id": 105}    
  v_fecha_inicio := TO_DATE ( JSON_VALUE(p_json_payload, '$.fecha_inicio'), 'YYYY-MM-DD' );
  v_sucursal_id := TO_NUMBER ( JSON_VALUE(p_json_payload, '$.sucursal_id') );

    -- 2. Lógica pesada usando esos parámetros    
  dbms_output.put_line('Migrando ventas desde: '
                       || v_fecha_inicio
                       || ' para sucursal: '
                       || v_sucursal_id);
    
    -- (Tu código de migración aquí...)
  COMMIT;
END;
/