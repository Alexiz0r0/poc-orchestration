SELECT 
    job_name, 
    state, 
    next_run_date, 
    repeat_interval,
    enabled
FROM user_scheduler_jobs;

BEGIN
  -- Sustituye el nombre por el que quieras borrar
  DBMS_SCHEDULER.DROP_JOB(job_name => 'JOB_REPORTE_NOCTURNO', force => TRUE);
END;
/


BEGIN
  FOR r IN (SELECT job_name FROM user_scheduler_jobs WHERE job_name LIKE 'JOB_%') LOOP
    DBMS_SCHEDULER.DROP_JOB(job_name => r.job_name, force => TRUE);
  END LOOP;
END;
/


SELECT 
    log_id, 
    job_name, 
    status, 
    actual_start_date, 
    run_duration
FROM user_scheduler_job_run_details
ORDER BY actual_start_date DESC;
