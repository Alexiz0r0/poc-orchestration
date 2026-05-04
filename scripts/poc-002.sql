CREATE OR REPLACE PROCEDURE hr.sp_notificar_java (
  p_endpoint VARCHAR2,
  p_job_name VARCHAR2
) AS
  req      utl_http.req;
  resp     utl_http.resp;
  v_body   VARCHAR2(4000);
  v_url    VARCHAR2(500);
BEGIN
  v_url := 'http://192.168.56.1:8087/api/reportes/' || p_endpoint;
  v_body := '{"job_name":"' || p_job_name || '","timestamp":"' || TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS') || '"}';
    
  -- Configuración de tiempo de espera
  utl_http.set_transfer_timeout(5);
  
  -- Usamos HTTP/1.0 para evitar problemas de persistencia en la PoC
  req := utl_http.begin_request(v_url, 'POST', 'HTTP/1.0');
  
  -- Headers mínimos necesarios
  utl_http.set_header(req, 'Content-Type', 'application/json');
  utl_http.set_header(req, 'Content-Length', LENGTHB(v_body));
  
  -- Escribir el cuerpo ANTES de pedir la respuesta
  utl_http.write_text(req, v_body);
  
  -- Obtener respuesta
  resp := utl_http.get_response(req);
  
  DBMS_OUTPUT.PUT_LINE('Conexión exitosa. Status: ' || resp.status_code);
  
  -- Cerramos la respuesta inmediatamente
  utl_http.end_response(resp);

EXCEPTION
  WHEN OTHERS THEN
    -- Forzar cierre en caso de error para liberar el puerto
    BEGIN utl_http.end_response(resp); EXCEPTION WHEN OTHERS THEN NULL; END;
    DBMS_OUTPUT.PUT_LINE('Fallo crítico: ' || SQLERRM);
    DBMS_OUTPUT.PUT_LINE('Ubicación: ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
END;
/