CREATE OR REPLACE PROCEDURE hr.sp_notificar_java (
  p_endpoint VARCHAR2,
  p_job_name VARCHAR2
) AS
  req      utl_http.req;
  resp     utl_http.resp;
  v_body   VARCHAR2(4000);
  v_url    VARCHAR2(500) := 'http://192.168.56.1:8087/api/reportes/' || p_endpoint;
BEGIN
  -- JSON sin espacios extras
  v_body := '{"job_name":"' || p_job_name || '","timestamp":"' || TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS') || '"}';
    
  utl_http.set_transfer_timeout(5);
  
  -- Iniciamos petición
  req := utl_http.begin_request(v_url, 'POST', 'HTTP/1.1');
  
  -- HEADERS CRÍTICOS
  utl_http.set_header(req, 'Host', '192.168.56.1'); -- Algunos servidores rechazan sin esto
  utl_http.set_header(req, 'Content-Type', 'application/json');
  utl_http.set_header(req, 'Content-Length', LENGTHB(v_body));
  utl_http.set_header(req, 'Connection', 'close'); -- Evita sesiones colgadas
  
  -- Escribimos el cuerpo
  utl_http.write_text(req, v_body);
  
  -- Obtenemos respuesta
  resp := utl_http.get_response(req);
  
  DBMS_OUTPUT.PUT_LINE('Éxito total. Código Spring: ' || resp.status_code);
  
  utl_http.end_response(resp);

EXCEPTION
  WHEN OTHERS THEN
    -- El bloque de abajo extrae el error real oculto tras el ORA-29273
    DBMS_OUTPUT.PUT_LINE('Fallo: ' || SQLERRM);
    DBMS_OUTPUT.PUT_LINE(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
    BEGIN utl_http.end_response(resp); EXCEPTION WHEN OTHERS THEN NULL; END;
END;
/