SELECT host, lower_port, upper_port, principal, privilege
FROM dba_host_aces
WHERE host = '192.168.56.1' AND principal = 'HR';

SELECT host, lower_port, upper_port, principal, privilege
FROM dba_host_aces
WHERE principal = 'SYSTEM';

SELECT host, lower_port, principal, privilege 
FROM dba_host_aces 
WHERE principal IN ('HR', 'SYSTEM');

SELECT host, lower_port, upper_port, ace_order, principal, privilege
FROM dba_host_aces
WHERE host = '192.168.56.1';



SET SERVEROUTPUT ON;
BEGIN
  -- Probamos el endpoint de éxito
  hr.sp_notificar_java('generar', 'PRUEBA_ORQUESTADOR_EXITOSA');
END;
/

DECLARE
  v_response_text VARCHAR2(4000);
BEGIN
  -- Intentamos llamar al endpoint de éxito directamente
  hr.sp_notificar_java('generar', 'TEST_MANUAL_CONEXION');
  
  DBMS_OUTPUT.PUT_LINE('Proceso terminado. Revisa los logs de Spring Boot.');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Error capturado en el Test: ' || SQLERRM);
    DBMS_OUTPUT.PUT_LINE('Stack Trace: ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
END;
/