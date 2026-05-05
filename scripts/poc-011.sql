select * from hr.report_jobs_config;

CREATE OR REPLACE PROCEDURE hr.sp_master_orquestador (
  p_report_id VARCHAR2
) AS
  v_sp_name VARCHAR2(100);
  v_json    CLOB;
BEGIN
  SELECT sp_name, parametros_json 
  INTO v_sp_name, v_json
  FROM hr.report_jobs_config
  WHERE report_id = p_report_id;

  -- VALIDACIÓN DE SEGURIDAD
  IF v_sp_name IS NULL THEN
     RAISE_APPLICATION_ERROR(-20002, 'Error: No se ha definido un SP_NAME para el reporte: ' || p_report_id);
  END IF;

  EXECUTE IMMEDIATE 'BEGIN ' || v_sp_name || '(:1, :2); END;'
  USING p_report_id, v_json;

  hr.sp_notificar_java('generar', p_report_id);
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    hr.sp_notificar_java('error', p_report_id);
    DBMS_OUTPUT.PUT_LINE('El ID de reporte no existe en la tabla de configuración.');
  WHEN OTHERS THEN
    hr.sp_notificar_java('error', p_report_id);
    RAISE;
END;
/