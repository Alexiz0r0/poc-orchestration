package com.alexiz.controller;

import java.util.Map;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.fasterxml.jackson.core.JsonProcessingException;

import tools.jackson.databind.ObjectMapper;

@RestController
@RequestMapping("/api/v2/config")
public class OrchesConfigController {

	private final JdbcTemplate jdbcTemplate;
	private final ObjectMapper objectMapper;

	public OrchesConfigController(JdbcTemplate jdbcTemplate, ObjectMapper objectMapper) {
		this.jdbcTemplate = jdbcTemplate;
		this.objectMapper = objectMapper;
	}

	// Opcional para ejecuciones de 5s
	@PostMapping("/programar/{reportId}")
	public String programarJob(@PathVariable String reportId, @RequestParam(required = false) String cron,
			@RequestParam String spName, @RequestBody Map<String, Object> params) throws JsonProcessingException {

		// 1. Serialización del JSON
		String jsonParams = objectMapper.writeValueAsString(params);

		// 2. MERGE en la tabla de control
		// Se pasan 9 parámetros para los 9 '?' del MERGE
		jdbcTemplate.update("""
				MERGE INTO hr.report_jobs_config c
				USING dual ON (c.report_id = ?)
				WHEN MATCHED THEN
				    UPDATE SET repeat_interval = ?, parametros_json = ?, sp_name = ?, is_enabled = 1
				WHEN NOT MATCHED THEN
				    INSERT (report_id, job_name, repeat_interval, parametros_json, sp_name, is_enabled)
				    VALUES (?, ?, ?, ?, ?, 1)
				""", reportId, cron, jsonParams, spName, // Para el MATCHED
				reportId, "JOB_" + reportId, cron, jsonParams, spName // Para el NOT MATCHED
		);

		// 3. Orquestación del Job (Aquí estaba el error de índices)
		String jobName = "JOB_" + reportId;

		// El bloque PL/SQL tiene exactamente 3 símbolos '?'
		String plsql = """
				 BEGIN
				    -- 1. Limpieza de jobs previos
				    BEGIN
				        DBMS_SCHEDULER.DROP_JOB(job_name => ?);
				    EXCEPTION WHEN OTHERS THEN NULL;
				    END;

				    -- 2. Creación del Job dinámico
				    DBMS_SCHEDULER.CREATE_JOB (
				        job_name            => ?,
				        job_type            => 'PLSQL_BLOCK',
				        job_action          => 'BEGIN hr.sp_master_orquestador(''' || ? || '''); END;',
				        start_date          => SYSTIMESTAMP + INTERVAL '5' SECOND,
				        enabled             => TRUE,
				        auto_drop           => TRUE
				    );
				END;
				""";

		// Pasamos exactamente 3 parámetros: jobName, jobName y reportId
		jdbcTemplate.update(plsql, jobName, jobName, reportId);

		return "✅ Reporte [" + reportId + "] recibido. Se ejecutará en 5 segundos usando " + spName;
	}
}