-- Tabla que usará Java para la configuración
CREATE TABLE hr.report_jobs_config (
    job_name        VARCHAR2(50) PRIMARY KEY,
    start_date      TIMESTAMP,
    repeat_interval VARCHAR2(100),
    is_enabled      NUMBER(1) DEFAULT 0,
    last_status     VARCHAR2(20)
);

-- Tabla destino para simular el "Paso Pesado" de migración
CREATE TABLE hr.employees_archive AS
SELECT * FROM hr.employees WHERE 1=0; 

CREATE OR REPLACE PROCEDURE hr.sp_migrar_datos AS
BEGIN
-- 1. Simulamos el tiempo de procesamiento (ej. 10 segundos en la PoC)
  dbms_session.sleep(10);    
-- 2. Lógica de negocio simulada
  EXECUTE IMMEDIATE 'TRUNCATE TABLE hr.employees_archive';
  INSERT INTO hr.employees_archive
    SELECT
      *
    FROM
      hr.employees;
-- Para probar la ruta de error en tu presentación, puedes descomentar esto:
-- RAISE_APPLICATION_ERROR(-20001, 'Error simulado en migración');
  COMMIT;
END;
/

CREATE OR REPLACE PROCEDURE hr.sp_notificar_java (
  p_endpoint VARCHAR2,
  p_job_name VARCHAR2
) AS
  req    utl_http.req;
  resp   utl_http.resp;
  v_body VARCHAR2(4000);
BEGIN
-- Payload JSON
  v_body := '{"job_name": "'
            || p_job_name
            || '", "timestamp": "'
            || to_char(sysdate, 'YYYY-MM-DD HH24:MI:SS')
            || '"}';
    
-- Petición a Spring Boot    
  req := utl_http.begin_request('http://192.168.56.1:8087/api/reportes/' || p_endpoint, 'POST', 'HTTP/1.1');
  utl_http.set_header(req, 'Content-Type', 'application/json');
  utl_http.set_header(req,
                      'Content-Length',
                      length(v_body));
  utl_http.write_text(req, v_body);
  resp := utl_http.get_response(req);
  utl_http.end_response(resp);
EXCEPTION
  WHEN OTHERS THEN
    -- En producción se guardaría en una tabla de logs        
    dbms_output.put_line('Error llamando a Java: ' || sqlerrm);
END;
/

BEGIN
-- 1. Crear Programas
-- Programa A: Migración pesada    
  dbms_scheduler.create_program(
    program_name   => 'PROG_HR_MIGRACION',
    program_type   => 'STORED_PROCEDURE',
    program_action => 'HR.SP_MIGRAR_DATOS',
    enabled        => TRUE
  );

-- Programa B1: Éxito (Llama al endpoint de generar reporte)    
  dbms_scheduler.create_program(
    program_name   => 'PROG_HR_JAVA_EXITO',
    program_type   => 'PLSQL_BLOCK',
    program_action => 'BEGIN hr.sp_notificar_java(''generar'', ''JOB_REPORTE_NOCTURNO''); END;',
    enabled        => TRUE
  );

-- Programa B2: Error (Llama al endpoint de fallo)    
  dbms_scheduler.create_program(
    program_name   => 'PROG_HR_JAVA_ERROR',
    program_type   => 'PLSQL_BLOCK',
    program_action => 'BEGIN hr.sp_notificar_java(''error'', ''JOB_REPORTE_NOCTURNO''); END;',
    enabled        => TRUE
  );

-- 2. Crear la Cadena    
  dbms_scheduler.create_chain(chain_name => 'CHAIN_HR_ORQUESTADOR');

-- 3. Definir Pasos    
  dbms_scheduler.define_chain_step('CHAIN_HR_ORQUESTADOR', 'STEP_MIGRAR', 'PROG_HR_MIGRACION');
  dbms_scheduler.define_chain_step('CHAIN_HR_ORQUESTADOR', 'STEP_EXITO', 'PROG_HR_JAVA_EXITO');
  dbms_scheduler.define_chain_step('CHAIN_HR_ORQUESTADOR', 'STEP_ERROR', 'PROG_HR_JAVA_ERROR');

-- 4. Definir Reglas
-- Regla de inicio    
  dbms_scheduler.define_chain_rule('CHAIN_HR_ORQUESTADOR', 'TRUE', 'START STEP_MIGRAR');
    
-- Regla de éxito    
  dbms_scheduler.define_chain_rule('CHAIN_HR_ORQUESTADOR', 'STEP_MIGRAR COMPLETED', 'START STEP_EXITO');
  dbms_scheduler.define_chain_rule('CHAIN_HR_ORQUESTADOR', 'STEP_EXITO COMPLETED', 'END');

-- Regla de error    
  dbms_scheduler.define_chain_rule('CHAIN_HR_ORQUESTADOR', 'STEP_MIGRAR FAILED', 'START STEP_ERROR');
  dbms_scheduler.define_chain_rule('CHAIN_HR_ORQUESTADOR', 'STEP_ERROR COMPLETED', 'END');

-- Habilitar la cadena    
  dbms_scheduler.enable('CHAIN_HR_ORQUESTADOR');
    
-- 5. Crear el Job basado en la cadena (Inicialmente deshabilitado, Java lo actualizará)    
  dbms_scheduler.create_job(
    job_name   => 'JOB_REPORTE_NOCTURNO',
    job_type   => 'CHAIN',
    job_action => 'CHAIN_HR_ORQUESTADOR',
    enabled    => FALSE
  );

END;
/
