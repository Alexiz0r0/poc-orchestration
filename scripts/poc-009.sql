-- Evolución de la tabla de control
ALTER TABLE hr.report_jobs_config ADD (
  report_id       VARCHAR2(50),  -- Identificador único para Spring Boot
  sp_name         VARCHAR2(100), -- Nombre del procedimiento real (ej: 'HR.SP_MIGRAR_VENTAS')
  parametros_json CLOB           -- El "Payload" que contiene fechas, IDs, etc.
);

CREATE OR REPLACE PROCEDURE hr.sp_master_orquestador (
  p_report_id VARCHAR2
) AS
  v_sp_name VARCHAR2(100);
  v_json    CLOB;
BEGIN
    -- Extraemos la configuración dinámica
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

    -- EJECUCIÓN DINÁMICA: Invocamos el SP de negocio pasando el JSON
  EXECUTE IMMEDIATE 'BEGIN '
                    || v_sp_name
                    || '(:1, :2); END;'
    USING p_report_id, v_json;

    -- Notificación de ÉXITO
  hr.sp_notificar_java('generar', p_report_id);
EXCEPTION
  WHEN OTHERS THEN
        -- Notificación de ERROR
    hr.sp_notificar_java('error', p_report_id);
    RAISE;
END;
/

-- Ejemplo de cómo se vería uno de tus 50 reportes por dentro
CREATE OR REPLACE PROCEDURE hr.sp_reporte_ventas (
  p_id   VARCHAR2,
  p_json CLOB
) AS
  v_sucursal NUMBER;
BEGIN
    -- "Desempaquetamos" lo que envió Java
  v_sucursal := TO_NUMBER ( JSON_VALUE(p_json, '$.sucursal_id') );
    
    -- Lógica pesada aquí...
  dbms_session.sleep(5);
  COMMIT;
END;
/

BEGIN
  dbms_scheduler.create_job(
    job_name   => 'JOB_TEST_PRODUCCION',
    job_type   => 'PLSQL_BLOCK',
    job_action => 'BEGIN hr.sp_master_orquestador(''REP_001''); END;',
    enabled    => TRUE
  );
END;
/

CREATE OR REPLACE PROCEDURE hr.sp_migrar_datos (
  p_id   VARCHAR2,
  p_json CLOB
) AS
  v_salary NUMBER;
BEGIN
  v_salary := NVL(TO_NUMBER(JSON_VALUE(p_json, '$.salary')), 0);
-- 1. Simulamos el tiempo de procesamiento (ej. 10 segundos en la PoC)
  dbms_session.sleep(10);    
-- 2. Lógica de negocio simulada
  EXECUTE IMMEDIATE 'TRUNCATE TABLE hr.employees_archive';
  INSERT INTO hr.employees_archive
    SELECT
      *
    FROM
      hr.employees
    WHERE
      salary > v_salary;
-- Para probar la ruta de error en tu presentación, puedes descomentar esto:
-- RAISE_APPLICATION_ERROR(-20001, 'Error simulado en migración');
  COMMIT;
END;
/