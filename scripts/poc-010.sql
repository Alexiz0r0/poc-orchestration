desc hr.report_jobs_config;

select * from hr.report_jobs_config;

TRUNCATE TABLE hr.report_jobs_config;

select * from hr.employees where salary > 599;

desc hr.employees;

DECLARE
  v_payload CLOB := '{"salary": 5000}';
BEGIN
  -- Simulamos lo que haría el orquestador maestro
  hr.sp_migrar_datos('REP_PRUEBA_01', v_payload);
  
  -- Verificamos si insertó algo
  FOR r IN (SELECT count(*) as total FROM hr.employees_archive) LOOP
    DBMS_OUTPUT.PUT_LINE('Migración exitosa. Empleados con sueldo > 5000: ' || r.total);
  END LOOP;
END;
/

SELECT report_id, job_name, parametros_json 
FROM hr.report_jobs_config 
WHERE report_id = 'REP_MIGRACION_SALARIOS';


