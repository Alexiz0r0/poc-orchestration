BEGIN
  -- 1. Intentar limpiar el ACE previo si existe (ignorar si falla)
  BEGIN
    DBMS_NETWORK_ACL_ADMIN.REMOVE_HOST_ACE(
      host => '192.168.56.1',
      lower_port => 8087,
      upper_port => 8087,
      ace => xs$ace_type(privilege_list => xs$name_list('connect', 'resolve'),
                         principal_name => 'SYSTEM',
                         principal_type => xs_acl.ptype_db));
  EXCEPTION WHEN OTHERS THEN NULL; END;

  -- 2. Crear el nuevo permiso ACE específico para HR
  DBMS_NETWORK_ACL_ADMIN.APPEND_HOST_ACE(
    host       => '192.168.56.1',
    lower_port => 8087,
    upper_port => 8087,
    ace        => xs$ace_type(privilege_list => xs$name_list('connect', 'resolve'),
                              principal_name => 'SYSTEM', -- Asegúrate que sea el dueño del SP
                              principal_type => xs_acl.ptype_db));
END;
/


