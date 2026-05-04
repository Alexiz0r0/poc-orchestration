BEGIN
  -- Cierra todas las conexiones HTTP persistentes activas en la sesión actual.
  -- Se usa para liberar recursos y asegurar que la próxima petición 
  -- tome las nuevas configuraciones de red o ACL.
  UTL_HTTP.CLOSE_PERSISTENT_CONNS;
END;
/

BEGIN
  -- APPEND_HOST_ACE añade una entrada de control de acceso (ACE) al host.
  DBMS_NETWORK_ACL_ADMIN.APPEND_HOST_ACE(
    host           => '192.168.56.1', -- La IP destino (tu máquina física/Ubuntu).
    ace            => xs$ace_type(
                        -- 'connect': Permite abrir conexiones TCP.
                        -- 'resolve': Permite traducir nombres de host (DNS).
                        privilege_list => xs$name_list('connect', 'resolve'),
                        principal_name => 'HR',      -- Usuario de BD que recibe el permiso.
                        principal_type => xs_acl.ptype_db -- Indica que es un usuario de BD.
                      )
  );
END;
/

BEGIN
  -- Permite la comunicación con cualquier IP que empiece con 192.168.56.
  -- El '*' actúa como comodín para todo el segmento de red.
  DBMS_NETWORK_ACL_ADMIN.APPEND_HOST_ACE(
    host           => '192.168.56.*',
    ace            => xs$ace_type(
                        privilege_list => xs$name_list('connect', 'resolve'),
                        principal_name => 'HR',
                        principal_type => xs_acl.ptype_db
                      )
  );
END;
/

BEGIN
  -- Este bloque restringe el permiso únicamente al puerto donde corre Spring Boot.
  DBMS_NETWORK_ACL_ADMIN.APPEND_HOST_ACE(
    host       => '192.168.56.1',
    lower_port => 8087, -- Puerto inicial del rango.
    upper_port => 8087, -- Puerto final del rango (mismo valor para un puerto único).
    ace        => xs$ace_type(
                    -- 'http': Privilegio específico para usar el protocolo HTTP.
                    privilege_list => xs$name_list('http'),
                    principal_name => 'SYSTEM', 
                    principal_type => xs_acl.ptype_db
                  )
  );
END;
/

