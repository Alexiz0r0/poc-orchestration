package com.alexiz.controller;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/config")
public class ConfigController {

	private final JdbcTemplate jdbcTemplate;

	public ConfigController(JdbcTemplate jdbcTemplate) {
		this.jdbcTemplate = jdbcTemplate;
	}

	// Tu Frontend llama a este endpoint para programar el job
	@PostMapping("/programar")
	public String programarJob(@RequestParam String cronExpression) {
		// 1. Guardamos la configuración en la tabla de control
		jdbcTemplate.update("MERGE INTO hr.report_jobs_config c "
				+ "USING dual ON (c.job_name = 'JOB_REPORTE_NOCTURNO') "
				+ "WHEN MATCHED THEN UPDATE SET repeat_interval = ?, is_enabled = 1 "
				+ "WHEN NOT MATCHED THEN INSERT (job_name, repeat_interval, is_enabled) VALUES ('JOB_REPORTE_NOCTURNO', ?, 1)",
				cronExpression, cronExpression);

		// 2. Modificamos el job directamente desde Java usando JDBC
		// (En un entorno más estricto, esto lo haría un SP_SYNC_JOBS programado cada 1
		// min)
		String plsql = "BEGIN " + "  DBMS_SCHEDULER.SET_ATTRIBUTE('JOB_REPORTE_NOCTURNO', 'repeat_interval', '"
				+ cronExpression + "'); " + "  DBMS_SCHEDULER.ENABLE('JOB_REPORTE_NOCTURNO'); " + "END;";

		jdbcTemplate.execute(plsql);

		return "Job programado y sincronizado con el cron: " + cronExpression;
	}
}
