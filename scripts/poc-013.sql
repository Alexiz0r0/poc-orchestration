ALTER TABLE hr.report_jobs_config ADD (
    status        VARCHAR2(20) DEFAULT 'PENDIENTE', -- PENDIENTE, EN_PROCESO, COMPLETADO, ERROR
    error_message CLOB,                             -- Para guardar el SQLERRM si algo falla
    last_run      TIMESTAMP                         -- Cuándo se ejecutó por última vez
);


CREATE OR REPLACE PROCEDURE hr.sp_master_orquestador (p_report_id VARCHAR2) AS
  v_sp_name  VARCHAR2(100);
  v_json     CLOB;
  v_error_msg VARCHAR2(4000); -- Variable para capturar el error
BEGIN
  -- 1. Marcamos como 'EN_PROCESO'
  UPDATE hr.report_jobs_config 
  SET status = 'EN_PROCESO', 
      error_message = NULL,
      last_run = SYSTIMESTAMP
  WHERE report_id = p_report_id;
  COMMIT;

  -- Obtenemos la configuración
  SELECT sp_name, parametros_json INTO v_sp_name, v_json
  FROM hr.report_jobs_config WHERE report_id = p_report_id;

  -- 2. Ejecución dinámica
  EXECUTE IMMEDIATE 'BEGIN ' || v_sp_name || '(:1, :2); END;' USING p_report_id, v_json;

  -- 3. Éxito: Actualizamos estado
  UPDATE hr.report_jobs_config 
  SET status = 'COMPLETADO' 
  WHERE report_id = p_report_id;
  COMMIT;
  
  hr.sp_notificar_java('generar', p_report_id);

EXCEPTION
  WHEN OTHERS THEN
    -- CAPTURA CORRECTA: Guardamos el error en la variable antes de usarla en el UPDATE
    v_error_msg := SQLERRM; 
    
    ROLLBACK; -- Deshacemos cualquier cambio pendiente en los datos del reporte

    UPDATE hr.report_jobs_config 
    SET status = 'ERROR', 
        error_message = v_error_msg 
    WHERE report_id = p_report_id;
    COMMIT;
    
    hr.sp_notificar_java('error', p_report_id);
    RAISE;
END;
/